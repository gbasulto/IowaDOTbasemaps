# Validation record — September 7, 2026

This is an initial implementation, not a claim of production verification in
the original incident application.

## Completed

- Retrieved the three public Web Map definitions and six child-layer item
  metadata records from ArcGIS. All three parent modification dates: July 16,
  2026. The bundled catalog records exact item IDs, URLs and timestamps.
- Downloaded all six live styles and their vector service metadata, normalized
  their relative paths, and validated the resulting styles with MapLibre's
  style validator: **zero validation errors in all six**.
- Feature/reference style layer counts: greyscale 98/28, dark 94/27,
  color 96/28. These counts are current observations, not fixed requirements.
- **14 programmatic JavaScript tests passed**, using actual Leaflet 1.3.1 and
  the R leaflet JavaScript binding in a simulated DOM. The WebGL adapter was
  mocked; this tests lifecycle and method integration, not pixels.
- Parsed every R script and Rd help file with R 4.5.1 through webR. Parsed
  DESCRIPTION and checked pure R argument/date helpers successfully.
- JavaScript syntax checked with Node.

The 14 lifecycle/integration checks cover:

1. Registration in the real R `LeafletWidget.methods` table.
2. All three DOT styles, relative resource URLs, fonts and z/y/x tile templates.
3. Excluding reference layers with `labels = FALSE`.
4. Explicit zero tile levels, avoiding incorrect truthy/falsy defaults.
5. Restricting API-key propagation to CARTO basemap hosts and redacting notices.
6. Low, noninteractive basemap panes and retained incident overlays.
7. Proxy replacement by ID without deleting incidents.
8. Clearing a basemap while its metadata request is pending.
9. Rapid replacements settling to the final requested map.
10. Group hide/show/clear lifecycle and incident-group preservation.
11. Metadata failure reporting without silent fallback.
12. Explicit fallback reporting and saved-definition loading.
13. Unsupported Web Map types and CRS failures.
14. CARTO raster removal without removing ordinary tile layers.

## Not completed here

- Native `R CMD build`, installation, or `R CMD check`/testthat execution.
  No native R was installed; system-package installation was blocked. The
  portable interpreter checks are not a substitute for those package checks.
- Real-browser WebGL rendering or visual/click verification in Shiny. The cloud
  browser blocked the local test URL. The supplied Shiny example must be run
  in a browser on the user's machine.
- Authenticated CARTO vector/raster requests, because no customer basemap key
  was supplied. Key handling was exercised with synthetic values in tests.
- Windows/macOS native installation, hidden-tab resizing and deployed Shiny
  hosting. The example includes a second map and tab for those checks.

The renderer bridge declares a newer Leaflet npm peer requirement than the R
package's bundled Leaflet 1.3.1. No second Leaflet library is injected to override
the R binding. Full bridge/GPU compatibility is a remaining local check.

## Reproduce local checks

From an installed package:

```r
IowaDOTbasemaps::runBasemapExample(launch.browser = TRUE)
```

From the editable package source, with dependencies installed:

```text
R CMD build IowaDOTbasemaps
R CMD check --no-manual IowaDOTbasemaps_0.1.0.tar.gz
```

The source ZIP includes `qa/` with the reproducible Node test harness and its
pinned dependency lockfile. From the ZIP's root:

```text
npm ci --prefix qa --ignore-scripts
node qa/run-tests.cjs
node qa/live-styles.cjs
node qa/check-r.cjs
```

The R source archive was assembled from the package source; it was not produced
by native `R CMD build` in this environment. It includes DESCRIPTION, NAMESPACE,
R code, help files, assets and tests in a normal source-package directory.
