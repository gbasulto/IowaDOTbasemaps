# Add an Iowa DOT Vector Basemap

Adds a managed vector basemap below ordinary Leaflet overlays. Resolves
the Web Map's feature and reference layers and their styles. Supplies
its own locally bundled JavaScript dependencies.

## Usage

``` r
addIowaBasemap(
  map,
  style = c("greyscale", "dark", "color"),
  group = NULL,
  layerId = NULL,
  labels = TRUE,
  item_id = NULL,
  source = c("live", "bundled"),
  fallback = FALSE,
  refresh = FALSE,
  opacity = 1,
  timeout = 30
)
```

## Arguments

- map:

  A
  [`leaflet()`](https://rstudio.github.io/leaflet/reference/leaflet.html)
  or
  [`leafletProxy()`](https://rstudio.github.io/leaflet/reference/leafletProxy.html)
  object.

- style:

  One of `"greyscale"`, `"dark"`, or `"color"`.

- group:

  Leaflet group name. Defaults to the DOT title. Use a group separate
  from incident overlays.

- layerId:

  Basemap identifier, default `ctremaps-dot-STYLE`. Reuse an ID to
  replace only that basemap.

- labels:

  Include visible reference/label layers from the DOT Web Map.

- item_id:

  Optional replacement public ArcGIS Web Map item ID. Not a tile-layer
  ID.

- source:

  Resolve the current Web Map in the browser, or use saved layer
  definitions. Both fetch styles and tiles online.

- fallback:

  When TRUE, a failed live Web Map request uses saved layer definitions
  with a visible warning. Does not recover style/tile failures.

- refresh:

  Bypass the one-hour, per-page metadata cache and request revalidation
  of metadata. Does not force tile re-downloads.

- opacity:

  Overall basemap opacity from zero to one.

- timeout:

  Timeout in seconds for each metadata HTTP request.

## Value

The map object, suitable for a pipe.

## Details

Requires Web Mercator, internet access and a WebGL-capable browser.
Default live mode follows changes published under the same Web Map ID.
Reference layers remain below incident overlays. Browser errors are
shown on the map and reported as `input$MAPID_basemap_status` in Shiny.
Initial loading, successful loading, warnings and errors are
asynchronous; successfully constructing the R widget is not proof that
its remote tiles loaded.

## See also

[`addCartoBasemap`](https://gbasulto.github.io/IowaDOTbasemaps/reference/addCartoBasemap.md),
[`dotBasemaps`](https://gbasulto.github.io/IowaDOTbasemaps/reference/dotBasemaps.md),
[`clearBasemaps`](https://gbasulto.github.io/IowaDOTbasemaps/reference/clearBasemaps.md)

## Examples

``` r
library(leaflet)
leaflet() |> addIowaBasemap("color") |> setView(-93.6, 42.0, 8)

{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"IowaDOTbasemapsAddDOT","args":[{"entry":{"style":"color","item_id":"77831691f545442e9bb57ed1e8ad7957","title":"Iowa DOT Color Basemap","modified":1784219858000,"layers":[{"id":"VectorTile_5611","type":"VectorTileLayer","layerType":"VectorTileLayer","title":"Color Basemap Features","styleUrl":"https://tiles.arcgis.com/tiles/8lRhdTsQyJpO52F1/arcgis/rest/services/Color_Basemap_Features/VectorTileServer/resources/styles/root.json","itemId":"543f00997b9a44b0b04d74d26d69ce07","visibility":true,"opacity":1,"item_modified":1784219640000,"item_title":"Color Basemap Features"},{"id":"VectorTile_910","type":"VectorTileLayer","layerType":"VectorTileLayer","title":"Color Basemap Labels","styleUrl":"https://tiles.arcgis.com/tiles/8lRhdTsQyJpO52F1/arcgis/rest/services/Color_Basemap_Labels/VectorTileServer/resources/styles/root.json","itemId":"f998d332039a4c9c814ab711a86a8025","isReference":true,"visibility":true,"opacity":1,"item_modified":1784219487000,"item_title":"Color Basemap Labels"}]},"group":"Iowa DOT Color Basemap","layerId":"IowaDOTbasemaps-dot-color","labels":true,"source":"live","fallback":false,"refresh":false,"opacity":1,"timeout":30000}]}],"setView":[[42,-93.59999999999999],8,[]]},"evals":[],"jsHooks":[]}
```
