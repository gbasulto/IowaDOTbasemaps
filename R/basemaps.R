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

#' Add an Iowa DOT vector basemap
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

#' Remove one IowaDOTbasemaps basemap
#' @export
removeBasemap <- function(map, layerId) {
  .scalar_text(layerId, "layerId")
  map <- .attach(map, FALSE)
  leaflet::invokeMethod(map, NULL, "IowaDOTbasemapsRemove", layerId)
}

#' Remove only basemaps managed by IowaDOTbasemaps
#' @export
clearBasemaps <- function(map) {
  map <- .attach(map, FALSE)
  leaflet::invokeMethod(map, NULL, "IowaDOTbasemapsClear")
}

#' Run the included Shiny regression example
#' @export
runBasemapExample <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE))
    stop("Install shiny to run this example.", call. = FALSE)
  shiny::runApp(system.file("examples", "shiny", package = "IowaDOTbasemaps"), ...)
}
