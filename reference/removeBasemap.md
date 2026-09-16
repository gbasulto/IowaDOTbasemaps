# Remove Basemaps Without Clearing Incident

Removes only the custom `IowaDOTbasemaps_basemap` category. Does not
call
[`clearShapes()`](https://rstudio.github.io/leaflet/reference/remove.html),
[`clearMarkers()`](https://rstudio.github.io/leaflet/reference/remove.html),
[`clearTiles()`](https://rstudio.github.io/leaflet/reference/remove.html),
or clear user overlay groups.

## Usage

``` r
removeBasemap(map, layerId)
```

## Arguments

- map:

  A Leaflet widget or proxy.

- layerId:

  The exact ID passed to a ctremaps basemap function.

## Value

The map object.

## Details

Regular
[`addTiles()`](https://rstudio.github.io/leaflet/reference/map-layers.html)
layers are outside this category. Conversely,
[`clearTiles()`](https://rstudio.github.io/leaflet/reference/remove.html)
does not remove IowaDOTbasemaps basemaps, including CARTO raster mode.
Standard
[`clearGroup()`](https://rstudio.github.io/leaflet/reference/remove.html),
[`hideGroup()`](https://rstudio.github.io/leaflet/reference/showGroup.html),
[`showGroup()`](https://rstudio.github.io/leaflet/reference/showGroup.html)
and layer controls work, provided basemaps and incidents have separate
group names.
