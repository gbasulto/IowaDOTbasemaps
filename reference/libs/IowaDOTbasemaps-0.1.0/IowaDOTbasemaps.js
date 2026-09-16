/* IowaDOTbasemaps 0.1.0 | MIT | Separate async basemap lifecycle from user overlays. */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory;
  else factory(root.L, root.maplibregl, root);
}(typeof window !== 'undefined' ? window : this, function (L, maplibre, env) {
  'use strict';
  var CATEGORY = 'IowaDOTbasemaps_basemap';
  var DOT_ATTR = '<a href="https://data.iowadot.gov/">Iowa Department of Transportation</a>';
  var CARTO_ATTR = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="https://carto.com/attributions">CARTO</a>';
  var clone = function (value) { return JSON.parse(JSON.stringify(value)); };
  var cache = new Map();

  function absolute(url, base) {
    return new URL(url, base).href.replace(/%7B/gi, '{').replace(/%7D/gi, '}');
  }

  function cartoKey(url, key) {
    var parsed = new URL(url);
    if (parsed.hostname === 'basemaps.cartocdn.com' ||
        parsed.hostname.endsWith('.basemaps.cartocdn.com')) parsed.searchParams.set('key', key);
    return parsed.href.replace(/%7B/gi, '{').replace(/%7D/gi, '}');
  }

  function redacted(message) {
    return String(message).replace(/([?&](?:key|token|api_key)=)[^\s&"']*/gi, '$1[redacted]');
  }

  async function json(url, opts) {
    var controller = new AbortController();
    var abort = function () { controller.abort(); };
    if (opts.signal.aborted) abort();
    opts.signal.addEventListener('abort', abort, { once: true });
    var timer = setTimeout(abort, opts.timeout);
    try {
      var response = await env.fetch(url, { signal: controller.signal,
        cache: opts.refresh ? 'reload' : 'default', credentials: 'omit' });
      if (!response.ok) throw new Error('HTTP ' + response.status + ' requesting basemap metadata.');
      var data = await response.json();
      if (data.error) throw new Error('ArcGIS: ' + data.error.message);
      return data;
    } catch (error) {
      if (!opts.signal.aborted && controller.signal.aborted)
        throw new Error('Basemap metadata request timed out.');
      throw error;
    } finally {
      clearTimeout(timer);
      opts.signal.removeEventListener('abort', abort);
    }
  }

  async function cachedJSON(url, opts) {
    var existing = cache.get(url);
    if (!opts.refresh && existing && Date.now() - existing.time < 3600000)
      return clone(existing.data);
    var data = await json(url, opts);
    // CARTO URLs contain a customer key: no global cache of those URLs.
    if (new URL(url).hostname.endsWith('arcgis.com')) cache.set(url, {time: Date.now(), data: clone(data)});
    return data;
  }

  function getLayers(webmap) {
    var layers = webmap && webmap.baseMap && webmap.baseMap.baseMapLayers;
    if (!Array.isArray(layers) || !layers.length) throw new Error('Web Map has no basemap layers.');
    layers.forEach(function (layer) {
      if (layer.layerType !== 'VectorTileLayer')
        throw new Error('DOT changed its basemap layer type; inspect the catalog before updating.');
    });
    return layers;
  }

  async function dotLayers(config, opts) {
    if (config.source === 'bundled') return clone(config.entry.layers);
    try {
      return getLayers(await cachedJSON('https://www.arcgis.com/sharing/rest/content/items/' +
        config.entry.item_id + '/data?f=json', opts));
    } catch (error) {
      if (opts.signal.aborted) throw error;
      if (!config.fallback || !config.entry.layers.length) throw error;
      opts.warn('Live DOT catalog unavailable; using the bundled layer definitions. Tiles still require internet.');
      return clone(config.entry.layers);
    }
  }

  async function styleURL(layer, opts) {
    if (layer.styleUrl) return layer.styleUrl;
    var service = layer.url;
    if (!service && layer.itemId) {
      var item = await cachedJSON('https://www.arcgis.com/sharing/rest/content/items/' +
        layer.itemId + '?f=json', opts);
      service = item.url;
    }
    if (!service || !/\/VectorTileServer\/?$/i.test(service))
      throw new Error('DOT layer has no usable style URL or vector tile service.');
    return service.replace(/\/$/, '') + '/resources/styles/root.json';
  }

  async function normalizeStyle(style, url, opts) {
    if (style.version !== 8 || !style.sources || !Array.isArray(style.layers))
      throw new Error('Unsupported vector style; expected MapLibre style version 8.');
    style = clone(style);
    if (style.glyphs) style.glyphs = absolute(style.glyphs, url);
    if (typeof style.sprite === 'string') style.sprite = absolute(style.sprite, url);
    else if (Array.isArray(style.sprite)) style.sprite.forEach(function (s) { s.url = absolute(s.url, url); });
    await Promise.all(Object.keys(style.sources).map(async function (name) {
      var source = style.sources[name];
      if (source.url) source.url = absolute(source.url, url);
      if (source.tiles) source.tiles = source.tiles.map(function (tile) { return absolute(tile, url); });
      if (!source.url || !/\/VectorTileServer\/?(?:\?.*)?$/i.test(source.url)) return;
      var service = source.url.replace(/\?.*$/, '').replace(/\/$/, '');
      var metadata = await cachedJSON(service + '?f=json', opts);
      var tileInfo = metadata.tileInfo || {};
      var sr = tileInfo.spatialReference || {};
      if (![3857, 102100, 102113].includes(sr.latestWkid || sr.wkid))
        throw new Error('DOT vector service is not Web Mercator.');
      if (!metadata.tiles || !metadata.tiles.length) throw new Error('DOT service has no tile templates.');
      source.tiles = metadata.tiles.map(function (tile) { return absolute(tile.replace(/^\//, ''), service + '/'); });
      // Prevent MapLibre requesting the ArcGIS HTML service page as TileJSON.
      delete source.url;
      // Preserve explicit 0: || would incorrectly discard a minLOD/maxLOD of 0.
      if (metadata.minLOD != null) source.minzoom = metadata.minLOD;
      if (metadata.maxLOD != null) source.maxzoom = metadata.maxLOD;
      if (metadata.copyrightText) source.attribution = metadata.copyrightText;
    }));
    // ArcGIS serves a single requested font stack; retain its primary font.
    style.layers.forEach(function (layer) {
      var fonts = layer.layout && layer.layout['text-font'];
      if (Array.isArray(fonts) && fonts.length > 1 && fonts.every(function (x) { return typeof x === 'string'; }))
        layer.layout['text-font'] = fonts.slice(0, 1);
    });
    return style;
  }

  async function prepareDOT(config, opts) {
    var layers = (await dotLayers(config, opts)).filter(function (layer) {
      return layer.visibility !== false && (config.labels || !layer.isReference);
    });
    if (!layers.length) throw new Error('DOT basemap has no visible layers.');
    // Promise.all preserves Web Map order even when labels download first.
    return Promise.all(layers.map(async function (layer) {
      var url = await styleURL(layer, opts);
      return { style: await normalizeStyle(await cachedJSON(url, opts), url, opts),
        opacity: layer.opacity == null ? 1 : layer.opacity,
        reference: !!layer.isReference };
    }));
  }

  async function prepareCarto(config, opts) {
    var names = {positron: 'positron', dark_matter: 'dark-matter', voyager: 'voyager'};
    var url = cartoKey('https://basemaps.cartocdn.com/gl/' + names[config.style] + '-gl-style/style.json', config.api_key);
    var style = await normalizeStyle(await json(url, opts), url, opts);
    return [{style: style, opacity: 1, reference: false}];
  }

  function report(layer, state, message) {
    if (!layer._activeMap) return;
    if (state === 'error') layer._failed = true;
    if (state === 'ready' && layer._failed) return;
    var map = layer._activeMap;
    message = redacted(message || '');
    var payload = {layerId: layer.config.layerId, provider: layer.provider,
      status: state, message: message};
    map.fire('IowaDOTbasemaps:status', payload);
    if (env.Shiny && typeof env.Shiny.setInputValue === 'function')
      env.Shiny.setInputValue(map.getContainer().id + '_basemap_status', payload, {priority: 'event'});
    if (state === 'error' || state === 'warning') {
      if (env.console) env.console.warn('[IowaDOTbasemaps] ' + message);
      if (layer._notice) map.removeControl(layer._notice);
      var notice = L.control({position: 'bottomleft'});
      notice.onAdd = function () {
        var div = L.DomUtil.create('div', 'IowaDOTbasemaps-notice');
        div.textContent = message;
        L.DomEvent.disableClickPropagation(div);
        return div;
      };
      layer._notice = notice.addTo(map);
    }
  }

  function pane(map, name, index) {
    var el = map.getPane(name) || map.createPane(name);
    el.style.zIndex = String(index);
    el.style.pointerEvents = 'none';
    L.DomUtil.addClass(el, 'IowaDOTbasemaps-pane');
    return name;
  }

  // Guard queued animation callbacks after a basemap is removed mid-pan/zoom.
  // This is a subclass; vendor code is kept unmodified.
  var SafeGL;
  function glLayer(options) {
    if (!L.MaplibreGL) throw new Error('MapLibre dependencies are missing.');
    if (!SafeGL) SafeGL = L.MaplibreGL.extend({
      _update: function () { if (this._map && this._glMap) return L.MaplibreGL.prototype._update.apply(this, arguments); },
      _transitionEnd: function () {
        if (!this._map || !this._glMap) return;
        this._glMap.resize();
        this._glMap.jumpTo({center: this._map.getCenter(), zoom: this._map.getZoom() - 1});
        this._zoomEnd();
      },
      onRemove: function (map) {
        L.MaplibreGL.prototype.onRemove.call(this, map);
        this._container = null;
      }
    });
    return new SafeGL(options);
  }

  var Basemap = L.Layer.extend({
    initialize: function (config, provider) {
      this.config = config; this.provider = provider; this._epoch = 0;
      this._children = []; this._panes = [];
      L.setOptions(this, {attribution: provider === 'dot' ? DOT_ATTR : CARTO_ATTR});
    },
    onAdd: function (map) {
      var self = this;
      self._activeMap = map;
      self._failed = false;
      var epoch = ++self._epoch;
      var abort = self._abort = new AbortController();
      var opts = {signal: abort.signal, timeout: self.config.timeout,
        refresh: !!self.config.refresh, warn: function (message) { report(self, 'warning', message); }};
      report(self, 'loading', 'Loading basemap.');
      if (self.provider === 'carto' && self.config.mode === 'raster') {
        self._addRaster(map);
        return;
      }
      var ready = self.provider === 'dot' ? prepareDOT(self.config, opts) : prepareCarto(self.config, opts);
      ready.then(function (styles) {
        // A removed or replaced basemap must never reappear after a slow fetch.
        if (abort.signal.aborted || epoch !== self._epoch || self._activeMap !== map) return;
        var loaded = 0;
        styles.forEach(function (prepared, i) {
          var name = 'IowaDOTbasemaps-' + L.stamp(self) + '-' + i;
          // All basemap canvases, including reference labels, remain below 400.
          pane(map, name, 200 + (prepared.reference ? 100 : 0) + Math.min(i, 50));
          self._panes.push(name);
          var child = glLayer({style: prepared.style, pane: name, interactive: false,
            preserveDrawingBuffer: false,
            transformRequest: self.provider === 'carto' ? function (url) {
              return {url: cartoKey(url, self.config.api_key)};
            } : undefined});
          self._children.push(child);
          child.addTo(map);
          child.getContainer().style.opacity = String(self.config.opacity * prepared.opacity);
          child.getContainer().style.pointerEvents = 'none';
          child.getMaplibreMap().on('load', function () {
            if (++loaded === styles.length && epoch === self._epoch)
              report(self, 'ready', 'Basemap loaded.');
          });
          child.getMaplibreMap().on('error', function (event) {
            if (epoch !== self._epoch) return;
            report(self, 'error', 'Basemap resource failed. Check connectivity, browser console, and credentials. ' +
              redacted(event.error && event.error.message || ''));
          });
        });
      }).catch(function (error) {
        if (abort.signal.aborted || epoch !== self._epoch) return;
        self._removeChildren(map);
        report(self, 'error', error.message + ' Your incident layers have not been removed.');
      });
    },
    _addRaster: function (map) {
      var self = this;
      var paths = {positron: 'light_all', dark_matter: 'dark_all', voyager: 'rastertiles/voyager'};
      var name = 'IowaDOTbasemaps-' + L.stamp(self) + '-raster';
      pane(map, name, 200); self._panes.push(name);
      var url = cartoKey('https://basemaps.cartocdn.com/' + paths[self.config.style] + '/{z}/{x}/{y}.png', self.config.api_key);
      var tile = L.tileLayer(url, {pane: name, opacity: self.config.opacity, maxZoom: 20});
      tile.on('load', function () { report(self, 'ready', 'Basemap loaded.'); });
      tile.on('tileerror', function () { report(self, 'error', 'CARTO raster tile failed. Check the basemap key and connectivity.'); });
      self._children.push(tile); tile.addTo(map);
    },
    _removeChildren: function (map) {
      this._children.forEach(function (child) { if (map.hasLayer(child)) map.removeLayer(child); });
      this._children = [];
      this._panes.forEach(function (name) {
        var el = map.getPane(name);
        if (el && el.parentNode) el.parentNode.removeChild(el);
        // Leaflet has no removePane(); remove only panes owned by this layer.
        if (map._panes) delete map._panes[name];
      });
      this._panes = [];
    },
    onRemove: function (map) {
      ++this._epoch;
      if (this._abort) this._abort.abort();
      this._removeChildren(map);
      if (this._notice) map.removeControl(this._notice);
      this._notice = null;
      this._activeMap = null;
    }
  });

  function checkCRS(map) {
    var code = map.options.crs && map.options.crs.code;
    if (code !== 'EPSG:3857' && code !== 'EPSG:900913')
      throw new Error('IowaDOTbasemaps requires standard Web Mercator (EPSG:3857).');
  }

  function register(map, config, provider) {
    checkCRS(map);
    var layer = new Basemap(config, provider);
    map.layerManager.addLayer(layer, CATEGORY, config.layerId, config.group);
  }

  // Functions are installed synchronously. leafletProxy sends dependencies with
  // each method call; no onRender callback or UI script tag is required.
  L.IowaDOTbasemaps = {Basemap: Basemap, normalizeStyle: normalizeStyle,
    prepareDOT: prepareDOT, cartoKey: cartoKey, getLayers: getLayers, redacted: redacted};
  if (typeof env.LeafletWidget !== 'undefined') {
    env.LeafletWidget.methods.IowaDOTbasemapsAddDOT = function (config) { register(this, config, 'dot'); };
    env.LeafletWidget.methods.IowaDOTbasemapsAddCarto = function (config) { register(this, config, 'carto'); };
    env.LeafletWidget.methods.IowaDOTbasemapsRemove = function (id) { this.layerManager.removeLayer(CATEGORY, id); };
    env.LeafletWidget.methods.IowaDOTbasemapsClear = function () { this.layerManager.clearLayers(CATEGORY); };
  }
  return L.IowaDOTbasemaps;
}));
