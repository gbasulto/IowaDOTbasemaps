#!/usr/bin/env bash
# Run from the package root. Requires curl. This is a maintainer-only operation.
set -euo pipefail
test -f DESCRIPTION
test -d inst/htmlwidgets/lib
curl -fSL --retry 2 --max-time 90 'https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js' -o inst/htmlwidgets/lib/maplibre/maplibre-gl.js
curl -fSL --retry 2 --max-time 90 'https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css' -o inst/htmlwidgets/lib/maplibre/maplibre-gl.css
curl -fSL --retry 2 --max-time 60 'https://unpkg.com/maplibre-gl@4.7.1/LICENSE.txt' -o inst/htmlwidgets/lib/maplibre/LICENSE.txt
curl -fSL --retry 2 --max-time 60 'https://unpkg.com/@maplibre/maplibre-gl-leaflet@0.0.22/leaflet-maplibre-gl.js' -o inst/htmlwidgets/lib/maplibre-leaflet/leaflet-maplibre-gl.js
curl -fSL --retry 2 --max-time 60 'https://unpkg.com/@maplibre/maplibre-gl-leaflet@0.0.22/LICENSE' -o inst/htmlwidgets/lib/maplibre-leaflet/LICENSE
