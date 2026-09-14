# Public API deliberately follows Leaflet's add* / remove* naming convention.

.scalar_text <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x)))
    stop(name, " must be one nonempty string.", call. = FALSE)
  x
}

.flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x))
    stop(name, " must be TRUE or FALSE.", call. = FALSE)
  x
}

.check_map <- function(map) {
  if (!inherits(map, "leaflet") && !inherits(map, "leaflet_proxy"))
    stop("map must be a leaflet() or leafletProxy() object.", call. = FALSE)
  crs <- map$x$options$crs$code
  if (!is.null(crs) && !crs %in% c("EPSG:3857", "EPSG:900913"))
    stop("IowaDOTbasemaps requires the standard Web Mercator Leaflet CRS.", call. = FALSE)
  invisible(map)
}

.dependencies <- function(vector = TRUE) {
  deps <- list()
  if (vector) {
    deps <- list(
      htmltools::htmlDependency("IowaDOTbasemaps-maplibre-gl", "4.7.1",
        src = "htmlwidgets/lib/maplibre", package = "IowaDOTbasemaps",
        script = "maplibre-gl.js", stylesheet = "maplibre-gl.css",
        all_files = FALSE),
      htmltools::htmlDependency("IowaDOTbasemaps-maplibre-leaflet", "0.0.22",
        src = "htmlwidgets/lib/maplibre-leaflet", package = "IowaDOTbasemaps",
        script = "leaflet-maplibre-gl.js", all_files = FALSE)
    )
  }
  c(deps, list(htmltools::htmlDependency("IowaDOTbasemaps", "0.1.0",
    src = "htmlwidgets", package = "IowaDOTbasemaps", script = "IowaDOTbasemaps.js",
    stylesheet = "IowaDOTbasemaps.css", all_files = FALSE)))
}

.attach <- function(map, vector = TRUE) {
  .check_map(map)
  map$dependencies <- c(map$dependencies, .dependencies(vector))
  map
}

#' Add an Authenticated CARTO Basemap
#'
#' Adds a CARTO basemap with visible attribution and scoped API-key propagation to CARTO basemap hosts.
#'
#' @details
#' The key reaches the browser in map data and requests, including in saved HTML.
#' Environment variables keep it out of your source code, not secret from viewers.
#' Use only a customer basemap key intended for browser use. Never supply
#' privileged account credentials. Normalization of a vector style never forwards
#' this key to non-CARTO hosts. Raster mode is useful when WebGL is unavailable,
#' but is subject to CARTO's raster-service lifecycle.
#'
#' @param map A Leaflet widget or proxy.
#' @param style CARTO style name.
#' @param api_key Your CARTO basemap key. Defaults to environment variable \code{CARTO_API_KEY}.
#' @param group Leaflet group name; defaults to the CARTO style title.
#' @param layerId Basemap identifier, default \code{IowaDOTbasemaps-carto-STYLE}.
#' @param mode Vector (default, MapLibre) or raster (standard Leaflet PNG tiles).
#' @param opacity Basemap opacity between zero and one.
#' @param timeout Per-metadata-request timeout in seconds.
#'
#' @return The map object.
#'
#' @examples
#' \dontrun{
#' leaflet::leaflet() |> addCartoBasemap("positron")
#' leaflet::leaflet() |> addCartoBasemap("voyager", mode = "raster")
#' }
#' @export
addIowaBasemap <- function(map, style = c("greyscale", "dark", "color"),
                          group = NULL, layerId = NULL, labels = TRUE,
                          item_id = NULL, source = c("live", "bundled"),
                          fallback = FALSE, refresh = FALSE,
                          opacity = 1, timeout = 30) {
  style <- match.arg(style)
  source <- match.arg(source)
  labels <- .flag(labels, "labels")
  fallback <- .flag(fallback, "fallback")
  refresh <- .flag(refresh, "refresh")
  catalog <- .dot_catalog()
  entry <- catalog$basemaps[[match(style, vapply(catalog$basemaps,
    function(x) x$style, character(1)))]]
  if (is.null(entry)) stop("Style is missing from the DOT catalog.", call. = FALSE)
  if (!is.null(item_id)) {
    .scalar_text(item_id, "item_id")
    if (!grepl("^[A-Fa-f0-9]{32}$", item_id))
      stop("item_id must be a 32-character ArcGIS Web Map item ID.", call. = FALSE)
    if (item_id != entry$item_id) {
      if (source == "bundled" || fallback)
        stop("A replacement item_id cannot use the old bundled fallback. ",
             "Refresh a catalog first, or use source = 'live', fallback = FALSE.",
             call. = FALSE)
      entry$item_id <- item_id
      entry$layers <- list()
    }
  }
  if (is.null(group)) group <- entry$title
  if (is.null(layerId)) layerId <- paste0("IowaDOTbasemaps-dot-", style)
  .scalar_text(group, "group")
  .scalar_text(layerId, "layerId")
  .render_options(opacity, timeout)
  map <- .attach(map)
  leaflet::invokeMethod(map, NULL, "IowaDOTbasemapsAddDOT", list(
    entry = entry, group = group, layerId = layerId, labels = labels,
    source = source, fallback = fallback, refresh = refresh,
    opacity = opacity, timeout = timeout * 1000
  ))
}

.render_options <- function(opacity, timeout) {
  if (!is.numeric(opacity) || length(opacity) != 1L || !is.finite(opacity) ||
      opacity < 0 || opacity > 1)
    stop("opacity must be between 0 and 1.", call. = FALSE)
  if (!is.numeric(timeout) || length(timeout) != 1L || !is.finite(timeout) || timeout <= 0)
    stop("timeout must be a positive number of seconds.", call. = FALSE)
}

#' Add an authenticated CARTO basemap
#'
#' @param map A Leaflet widget or proxy.
#' @param style CARTO style string ("positron", "dark_matter", "voyager")
#' @param api_key Your CARTO basemap key. Defaults to environment variable
#'   \code{CARTO_API_KEY}.
#' @param group Leaflet group name; defaults to the CARTO style title.
#' @param layerId Basemap identifier, default \code{IowaDOTbasemaps-carto-STYLE}.
#' @param mode Vector (default, MapLibre) or raster (standard Leaflet PNG
#'   tiles).
#' @param opacity Basemap opacity between zero and one.
#' @param timeout Per-metadata-request timeout in seconds.
#'
#' @return The map object.
#' Adds a CARTO basemap with visible attribution and scoped API-key propagation
#' to CARTO basemap hosts.
#'
#' The key reaches the browser in map data and requests, including in saved
#' HTML. Environment variables keep it out of your source code, not secret from
#' viewers. Use only a customer basemap key intended for browser use. Never
#' supply privileged account credentials. Normalization of a vector style never
#' forwards this key to non-CARTO hosts. Raster mode is useful when WebGL is
#' unavailable, but is subject to CARTO's raster-service lifecycle.
#'
#' @examples
#' \dontrun{
#' leaflet::leaflet() |> addCartoBasemap("positron")
#' leaflet::leaflet() |> addCartoBasemap("voyager", mode = "raster")
#' }
#' @export
addCartoBasemap <- function(map, style = c("positron", "dark_matter", "voyager"),
                            api_key = Sys.getenv("CARTO_API_KEY"),
                            group = NULL, layerId = NULL,
                            mode = c("vector", "raster"), opacity = 1, timeout = 30) {
  style <- match.arg(style)
  mode <- match.arg(mode)
  if (!is.character(api_key) || length(api_key) != 1L || is.na(api_key) ||
      !nzchar(trimws(api_key)))
    stop("Set CARTO_API_KEY in .Renviron and restart R, or supply api_key. ",
         "Use a CARTO basemap key, not a private account/API credential.", call. = FALSE)
  if (is.null(group)) group <- paste("CARTO", switch(style,
    positron = "Positron", dark_matter = "Dark Matter", voyager = "Voyager"))
  if (is.null(layerId)) layerId <- paste0("IowaDOTbasemaps-carto-", style)
  .scalar_text(group, "group")
  .scalar_text(layerId, "layerId")
  .render_options(opacity, timeout)
  map <- .attach(map, vector = mode == "vector")
  leaflet::invokeMethod(map, NULL, "IowaDOTbasemapsAddCarto", list(
    style = style, api_key = trimws(api_key), group = group, layerId = layerId,
    mode = mode, opacity = opacity, timeout = timeout * 1000
  ))
}

#' Remove Basemaps Without Clearing Incidents
#'
#' Removes only the custom \code{IowaDOTbasemaps_basemap} category. Does not call
#' \code{clearShapes()}, \code{clearMarkers()}, \code{clearTiles()}, or clear
#' user overlay groups.
#'
#' @details
#' Regular \code{addTiles()} layers are outside this category. Conversely,
#' \code{clearTiles()} does not remove IowaDOTbasemaps basemaps, including CARTO raster
#' mode. Standard \code{clearGroup()}, \code{hideGroup()}, \code{showGroup()} and
#' layer controls work, provided basemaps and incidents have separate group names.
#'
#' @param map A Leaflet widget or proxy.
#' @param layerId The exact ID passed to a IowaDOTbasemaps basemap function.
#'
#' @aliases removeBasemap
#'
#' @return The map object.
#'
#' @export
removeBasemap <- function(map, layerId) {
  .scalar_text(layerId, "layerId")
  map <- .attach(map, FALSE)
  leaflet::invokeMethod(map, NULL, "IowaDOTbasemapsRemove", layerId)
}

#' Inspect and Refresh Iowa DOT Basemap Definitions
#'
#' Lists configured basemaps, checks current public Web Map and child-layer
#' metadata, or saves a refreshed catalog. The installed package is never
#' modified by these functions.
#'
#' @details
#' Set \code{options(IowaDOTbasemaps.dot_catalog = "path/to/catalog.json")} to use a
#' saved catalog, or supply the parsed catalog list. The option is
#' session-scoped. A date change is a metadata signal, not evidence that all
#' roadway geometry changed. Unchanged dates cannot prove identical tile bytes.
#' Failed checks return \code{changed = NA}, not FALSE. Refresh validates all
#' three entries before writing. Tiles and complete styles are not stored in
#' this catalog.
#'
#' @param timeout Per-request timeout in seconds.
#' @param file Destination JSON path; its parent directory must exist.
#' @param item_ids Optional named character vector of replacement Web Map IDs,
#'   using names \code{greyscale}, \code{dark}, or \code{color}.
#' @param overwrite Allow replacement of an existing destination file.
#'
#' @aliases checkDOTBasemaps refreshDOTBasemaps
#'
#' @return \code{dotBasemaps()} returns a data frame. \code{checkDOTBasemaps()}
#'   returns dates, a change indicator and per-map status.
#'   \code{refreshDOTBasemaps()} invisibly returns the normalized saved path.
#'
#' @examples
#' dotBasemaps()
#' \dontrun{
#' checkDOTBasemaps()
#' refreshDOTBasemaps("dot-basemaps-current.json")
#' options(IowaDOTbasemaps.dot_catalog = "dot-basemaps-current.json")
#' }
#' @export
clearBasemaps <- function(map) {
  map <- .attach(map, FALSE)
  leaflet::invokeMethod(map, NULL, "IowaDOTbasemapsClear")
}

#' Run the Shiny Basemap Regression Example
#'
#' Launches an app exercising basemap replacement, incident proxy updates,
#' popups, multiple maps and a hidden tab. CARTO requires your basemap key;
#' Iowa DOT does not currently require a key.
#'
#' @param ... Arguments to \code{shiny::runApp()}, such as
#'   \code{launch.browser = TRUE}.
#'
#' @return The result of \code{shiny::runApp()}.
#'
#' @export
runBasemapExample <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE))
    stop("Install shiny to run this example.", call. = FALSE)
  shiny::runApp(system.file("examples", "shiny", package = "IowaDOTbasemaps"), ...)
}
