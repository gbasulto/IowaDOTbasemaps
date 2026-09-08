# Maintaining IowaDOTbasemaps

## What updates automatically

In live mode, changes to DOT layers/styles under the same Web Map ID are
discovered on page load or after the one-hour metadata cache expires. Reload,
or replace the basemap with `refresh = TRUE`. Tiles follow provider HTTP caching.
An already-open map does not monitor the portal continuously.

`checkDOTBasemaps()` compares Web Map and child-layer metadata with your catalog.
It does not compare tile bytes. A modification date is not proof that roadway
geometry changed, and an unchanged date is not proof of identical tile content.

## Adopt a replacement Web Map ID

For a single map:

```r
leaflet::leaflet() |>
  IowaDOTbasemaps::addIowaDOTBasemap("color", item_id = "NEW_32_CHARACTER_WEB_MAP_ID")
```

Use an actual **Web Map** ID, not a child vector-layer ID. The placeholder is not
executable. A replacement ID cannot use an old bundled fallback.

To save new IDs and their definitions:

```r
IowaDOTbasemaps::refreshDOTBasemaps(
  "dot-basemaps-current.json",
  item_ids = c(color = "NEW_32_CHARACTER_WEB_MAP_ID")
)
options(IowaDOTbasemaps.dot_catalog = "dot-basemaps-current.json")
IowaDOTbasemaps::dotBasemaps()
```

Unmentioned styles retain their IDs. All three maps are fetched and validated
before writing. Use `overwrite = TRUE` only when deliberately replacing a file.
Deploy the catalog alongside your app and set its path at startup. The option is
session-scoped. `source = "bundled"` means this configured catalog (or the installed
default); styles and tiles still come from live services. It is not an archive.

## Release a package update

Unzip the editable source. After modifying the code, examples and `man/` help,
run in a terminal from its parent directory:

```text
R CMD build IowaDOTbasemaps
R CMD check --no-manual IowaDOTbasemaps_0.1.0.tar.gz
R CMD INSTALL IowaDOTbasemaps_0.1.0.tar.gz
```

Install dependencies and `testthat` first. The package itself has no compiled
code. To update the shipped catalog, create one with `refreshDOTBasemaps()`,
review it and copy it to `inst/extdata/dot-basemaps.json` before rebuilding.

Before a new release, update DESCRIPTION's Version, the IowaDOTbasemaps dependency
version in `R/basemaps.R`, the user-agent in `R/catalog.R`, and NEWS.md. The
browser asset version must change when its JavaScript changes. Restart R and
reload the browser after installing an update to a running Shiny application.

The `man/` files are maintained directly. Source comments are abbreviated;
do not run roxygen as a substitute for updating the full help files.

## Renderer updates

Pinned assets: MapLibre GL JS 4.7.1 and maplibre-gl-leaflet 0.0.22. IowaDOTbasemaps does
not ship a second copy of Leaflet: the R leaflet package owns that dependency.

R leaflet currently declares Leaflet JavaScript 1.3.1; the renderer bridge's npm
peer declaration is newer (1.9.3+). This is an explicit compatibility risk:
programmatic lifecycle tests use the actual 1.3.1 Leaflet/R binding with a mocked
GPU adapter, so full visual compatibility still needs the Shiny regression test.

To update a renderer, review upstream compatibility, then update explicit
versions together in `tools/vendor-assets.sh` and `R/basemaps.R`. Run the shell
script from the package root (Git Bash works on Windows). Retain vendor license
files and verify downloads. Rebuild and test before distributing the release.

`inst/htmlwidgets/IowaDOTbasemaps.js` owns ArcGIS URL normalization, the custom Leaflet
category and asynchronous cancellation. Its `SafeGL` subclass guards callbacks
after removal without editing the vendor script.

Required local regression checks:

1. All three DOT maps with and without labels; normal marker and line popups.
2. Initial widget and the first basemap added through `leafletProxy()`.
3. Rapid replacement before loading finishes; clear/hide/show and layer controls.
4. Pan, zoom, resize, hidden tabs, and multiple maps.
5. CARTO vector and raster with your real basemap key.
6. A bad item ID or unavailable service: visible error, incident overlays retained.

Record results in VALIDATION.md and changes in NEWS.md. The supplied regression
app is launched with `IowaDOTbasemaps::runBasemapExample(launch.browser = TRUE)`.

## Source control

This project can be put in a private Git repository; none was created or
published for you. Commit source and vendored dependencies. Never commit
`.Renviron`, customer keys or HTML widgets containing keys.
