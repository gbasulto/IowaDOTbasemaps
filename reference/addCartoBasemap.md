# Add an authenticated CARTO basemap

Add an authenticated CARTO basemap

## Usage

``` r
addCartoBasemap(
  map,
  style = c("positron", "dark_matter", "voyager"),
  api_key = Sys.getenv("CARTO_API_KEY"),
  group = NULL,
  layerId = NULL,
  mode = c("vector", "raster"),
  opacity = 1,
  timeout = 30
)
```

## Arguments

- map:

  A Leaflet widget or proxy.

- style:

  CARTO style string ("positron", "dark_matter", "voyager")

- api_key:

  Your CARTO basemap key. Defaults to environment variable
  `CARTO_API_KEY`.

- group:

  Leaflet group name; defaults to the CARTO style title.

- layerId:

  Basemap identifier, default `IowaDOTbasemaps-carto-STYLE`.

- mode:

  Vector (default, MapLibre) or raster (standard Leaflet PNG tiles).

- opacity:

  Basemap opacity between zero and one.

- timeout:

  Per-metadata-request timeout in seconds.

## Value

The map object. Adds a CARTO basemap with visible attribution and scoped
API-key propagation to CARTO basemap hosts.

The key reaches the browser in map data and requests, including in saved
HTML. Environment variables keep it out of your source code, not secret
from viewers. Use only a customer basemap key intended for browser use.
Never supply privileged account credentials. Normalization of a vector
style never forwards this key to non-CARTO hosts. Raster mode is useful
when WebGL is unavailable, but is subject to CARTO's raster-service
lifecycle.

## Examples

``` r
if (FALSE) { # \dontrun{
leaflet::leaflet() |> addCartoBasemap("positron")
leaflet::leaflet() |> addCartoBasemap("voyager", mode = "raster")
} # }
```
