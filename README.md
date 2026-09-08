
<!-- README.md is generated from README.Rmd. Please edit that file -->

# IowaDOTbasemaps

Iowa DOT for R Leaflet maps and Shiny. Version 0.1.0.

## Install

You can install the development version of IowaDOTbasemaps from GitHub
with:

``` r
# install.packages("pak")
pak::pak("gbasulto/IowaDOTbasemaps")
```

Requires R 4.1 or newer. IowaDOTbasemaps has no compiled code: with
dependencies already installed, IowaDOTbasemaps itself does not require
Rtools. The ZIP is an editable source project, **not** a Windows binary
R package.

## First map

``` r
library(leaflet)
library(IowaDOTbasemaps)

leaflet() |>
  addIowaBasemap("greyscale") |>
  setView(-93.62, 42.02, 10) |>
  addCircleMarkers(lng = -93.62, lat = 42.02,
                   color = "red", radius = 10, popup = "Example incident")
```

Names follow Leaflet’s existing camel-case convention.

| Function | Purpose |
|----|----|
| `addIowaBasemap()` | Add greyscale, dark greyscale or color DOT vector basemap |
| `addCartoBasemap()` | Add authenticated CARTO Positron, Dark Matter or Voyager |
| `removeBasemap()` | Remove a IowaDOTbasemaps basemap by `layerId` |
| `clearBasemaps()` | Remove IowaDOTbasemaps basemaps while retaining incident overlays |
| `dotBasemaps()` | List configured DOT maps and snapshot dates |
| `checkDOTBasemaps()` | Compare current Web Map/child metadata with your catalog |
| `refreshDOTBasemaps()` | Save a refreshed catalog or adopt replacement IDs |
| `runBasemapExample()` | Run the bundled Shiny regression example |

## DOT styles

| `style` | DOT name | Web Map ID |
|----|----|----|
| `"greyscale"` | Iowa DOT Greyscale Basemap | `805a6f2de49841e8b390cd54d91e53ad` |
| `"dark"` | Iowa DOT Dark Greyscale Basemap | `ef58c25cf11b4a58a50e85e1e01b0bed` |
| `"color"` | Iowa DOT Color Basemap | `77831691f545442e9bb57ed1e8ad7957` |

All three public Web Map items reported a July 16, 2026 modification
date when checked on September 7. This is an item date, not the
acquisition date of every road feature. Each currently contains feature
and reference/label vector layers.

``` r
leaflet() |> addIowaBasemap("dark")
leaflet() |> addIowaBasemap("color", labels = FALSE)
dotBasemaps()
```

Live mode reads the current Web Map, referenced styles and vector
service metadata in the browser. Relative glyph/sprite paths and ArcGIS
tile templates are normalized. Service min/max tile levels are respected
for overzooming. JavaScript dependencies are bundled locally; no UI
script tags are necessary.

## CARTO

Put your **CARTO basemap key** in `.Renviron`, then restart R:

``` text
CARTO_API_KEY=your_actual_basemap_key
```

``` r
leaflet() |> addCartoBasemap("positron")
leaflet() |> addCartoBasemap("dark_matter")
leaflet() |> addCartoBasemap("voyager", mode = "raster")
leaflet() |> addCartoBasemap(api_key = Sys.getenv("CARTO_API_KEY"))
```

Vector is the default because CARTO recommends it while retiring its
raster service. Raster remains an explicit option for standard Leaflet
PNG tiles, including environments without WebGL. An empty key produces a
clear R error.

Environment variables keep the key out of scripts, **not secret from
viewers**. It reaches the browser and any saved HTML. Supply only a
basemap key intended for client use, never privileged account
credentials. Key propagation is limited to CARTO basemap hosts, and
attribution stays visible.

## Minimal change in Shiny

Replace your basemap call:

``` r
output$map <- renderLeaflet({
  leaflet() |>
    addIowaBasemap("greyscale", layerId = "background", group = "Basemap") |>
    setView(-93.6, 42, 7)
})
```

Keep your incident pipeline, for example:

``` r
observeEvent(incidents(), {
  leafletProxy("map", data = incidents()) |>
    clearGroup("Incidents") |>
    addPolylines(group = "Incidents", color = "blue", weight = 5)
})
```

To replace only the background later, reuse its ID:

``` r
leafletProxy("map") |>
  addIowaBasemap("color", layerId = "background", group = "Basemap")

leafletProxy("map") |>
  addCartoBasemap("positron", layerId = "background", group = "Basemap")

leafletProxy("map") |> removeBasemap("background")
leafletProxy("map") |> clearBasemaps()
```

Dependencies are attached to widgets and proxies, including the first
proxy invocation. Basemaps and incidents must have distinct groups. The
IowaDOTbasemaps category is separate from normal markers, shapes and
tiles. `clearTiles()` does not remove IowaDOTbasemaps basemaps, even in
CARTO raster mode. `clearBasemaps()` does not remove an older
`addTiles()`/`addProviderTiles()` background; remove that old basemap
call when adopting IowaDOTbasemaps.

## Layer controls

``` r
leaflet() |>
  addIowaBasemap("greyscale", group = "DOT greyscale") |>
  addIowaBasemap("dark", group = "DOT dark") |>
  addIowaBasemap("color", group = "DOT color") |>
  hideGroup(c("DOT dark", "DOT color")) |>
  addLayersControl(
    baseGroups = c("DOT greyscale", "DOT dark", "DOT color"),
    options = layersControlOptions(collapsed = FALSE)
  ) |>
  setView(-93.6, 42, 7)
```

Feature and label layers are managed together below ordinary overlay
panes. Basemap panes do not intercept clicks. A late response cannot
restore a basemap that has been cleared or replaced. Removal releases
owned canvases and panes. This addresses overlap and
asynchronous-lifecycle problems; the exact failure in the user’s
original full application has not been diagnosed here.

## Updating

Routine DOT updates under the same Web Map ID do not require
reinstalling the package. Reload the page. Metadata is cached in-page
for one hour; bypass it with:

``` r
leafletProxy("map") |>
addIowaBasemap("greyscale", layerId = "background", refresh = TRUE)

checkDOTBasemaps()
refreshDOTBasemaps("dot-basemaps-current.json")
options(IowaDOTbasemaps.dot_catalog = "dot-basemaps-current.json")
```

The option is session-scoped; put it at app startup to keep using your
catalog. Use `overwrite = TRUE` to deliberately replace an existing
snapshot. Failed checks return `changed = NA`, not FALSE. See
**MAINTENANCE.md** for new Web Map IDs and renderer/package releases.

`source = "bundled"` uses saved *layer definitions*, not frozen tiles or
complete styles. `fallback = TRUE` explicitly uses those definitions
when the live Web Map lookup fails, with a warning. Neither repairs
unavailable tiles nor works offline. Default live mode does not silently
fall back.

## Run the example

``` r
IowaDOTbasemaps::runBasemapExample(launch.browser = TRUE)
```

Click markers and lines, update incidents, switch rapidly, clear/restore
the basemap, pan/zoom and open the second tab. CARTO requires your key.
Coordinates are synthetic. For diagnostics inspect
`input$map_basemap_status`, substituting your output ID. Loading, ready,
warning and error states are reported.

Requires internet, standard Web Mercator and a WebGL-capable browser for
vector maps. Use an external Chrome/Edge/Firefox window if RStudio
Viewer has graphics restrictions. The DOT controls coverage; this
package does not invent an outside-Iowa background. Read
**VALIDATION.md** for completed checks and limits.

## Primary references

- <https://data.iowadot.gov/maps/805a6f2de49841e8b390cd54d91e53ad>
- <https://data.iowadot.gov/maps/ef58c25cf11b4a58a50e85e1e01b0bed>
- <https://data.iowadot.gov/maps/77831691f545442e9bb57ed1e8ad7957>
- <https://rstudio.github.io/leaflet/articles/extending.html>
- <https://developers.arcgis.com/web-map-specification/objects/vectorTileLayer/>
  - <https://github.com/maplibre/maplibre-gl-leaflet>
- <https://docs.carto.com/faqs/carto-basemaps>

Package code: MIT. Bundled third-party assets retain their own licenses;
see `inst/NOTICE.md` and the adjacent vendor license files.
