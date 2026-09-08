.dot_catalog <- function(catalog = getOption("IowaDOTbasemaps.dot_catalog", NULL)) {
  if (is.null(catalog))
    catalog <- system.file("extdata", "dot-basemaps.json", package = "IowaDOTbasemaps")
  if (is.character(catalog)) {
    .scalar_text(catalog, "catalog")
    if (!file.exists(catalog)) stop("DOT catalog file does not exist.", call. = FALSE)
    catalog <- jsonlite::fromJSON(catalog, simplifyVector = FALSE)
  }
  if (!is.list(catalog) || !identical(as.integer(catalog$schema_version), 1L) ||
      !is.list(catalog$basemaps) || length(catalog$basemaps) != 3L)
    stop("Invalid DOT catalog; expected schema_version 1 and three basemaps.", call. = FALSE)
  styles <- vapply(catalog$basemaps, function(x) .scalar_text(x$style, "style"), character(1))
  if (!setequal(styles, c("greyscale", "dark", "color")) || anyDuplicated(styles))
    stop("DOT catalog must contain greyscale, dark, and color exactly once.", call. = FALSE)
  for (entry in catalog$basemaps) {
    .scalar_text(entry$title, "title")
    .scalar_text(entry$item_id, "item_id")
    if (!grepl("^[A-Fa-f0-9]{32}$", entry$item_id) || !is.list(entry$layers))
      stop("Invalid catalog item ID or layers.", call. = FALSE)
  }
  catalog
}

.as_time <- function(x) {
  if (is.null(x)) return(NA_character_)
  format(as.POSIXct(x / 1000, origin = "1970-01-01", tz = "UTC"),
    "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
}

#' List the three Iowa DOT basemaps
#' @export
dotBasemaps <- function() {
  catalog <- .dot_catalog()
  do.call(rbind, lapply(catalog$basemaps, function(x) data.frame(
    style = x$style, title = x$title, item_id = x$item_id,
    snapshot_modified = .as_time(x$modified),
    url = paste0("https://data.iowadot.gov/maps/", x$item_id),
    stringsAsFactors = FALSE)))
}

.get_json <- function(url, timeout = 30) {
  handle <- curl::new_handle(timeout = timeout, connecttimeout = min(10, timeout),
    useragent = "IowaDOTbasemaps/0.1.0 (public basemap metadata)")
  response <- curl::curl_fetch_memory(url, handle = handle)
  if (response$status_code >= 400)
    stop("Metadata request failed with HTTP ", response$status_code, call. = FALSE)
  result <- jsonlite::fromJSON(rawToChar(response$content), simplifyVector = FALSE)
  if (!is.null(result$error))
    stop("ArcGIS error: ", result$error$message, call. = FALSE)
  result
}

.item_url <- function(id, data = FALSE) {
  paste0("https://www.arcgis.com/sharing/rest/content/items/", id,
    if (data) "/data" else "", "?f=json")
}

.live_entry <- function(entry, timeout) {
  meta <- .get_json(.item_url(entry$item_id), timeout)
  if (!identical(meta$type, "Web Map")) stop("Item is not an ArcGIS Web Map.")
  webmap <- .get_json(.item_url(entry$item_id, TRUE), timeout)
  layers <- webmap$baseMap$baseMapLayers
  if (!is.list(layers) || !length(layers)) stop("Web Map has no basemap layers.")
  for (i in seq_along(layers)) {
    layer <- layers[[i]]
    if (!identical(layer$layerType, "VectorTileLayer"))
      stop("Unsupported basemap layer type; inspect the updated Web Map.")
    if (!is.null(layer$itemId)) {
      item <- .get_json(.item_url(layer$itemId), timeout)
      layers[[i]]$item_modified <- item$modified
      layers[[i]]$item_title <- item$title
    }
  }
  list(style = entry$style, item_id = entry$item_id, title = meta$title,
       modified = meta$modified, layers = layers)
}

#' Check Web Map and child-layer modification dates and definitions
#' @export
checkDOTBasemaps <- function(timeout = 30) {
  .render_options(1, timeout)
  catalog <- .dot_catalog()
  do.call(rbind, lapply(catalog$basemaps, function(old) {
    live <- tryCatch(.live_entry(old, timeout), error = identity)
    failed <- inherits(live, "error")
    data.frame(style = old$style, item_id = old$item_id,
      snapshot_modified = .as_time(old$modified),
      live_modified = if (failed) NA_character_ else .as_time(live$modified),
      changed = if (failed) NA else !identical(old, live),
      status = if (failed) conditionMessage(live) else "ok",
      stringsAsFactors = FALSE)
  }))
}

#' Save a refreshed catalog without modifying the installed package
#' @export
refreshDOTBasemaps <- function(file, item_ids = NULL, overwrite = FALSE, timeout = 30) {
  .scalar_text(file, "file")
  .flag(overwrite, "overwrite")
  .render_options(1, timeout)
  if (file.exists(file) && !overwrite)
    stop("File exists. Choose another file or use overwrite = TRUE.", call. = FALSE)
  if (!dir.exists(dirname(file))) stop("The destination directory does not exist.", call. = FALSE)
  catalog <- .dot_catalog()
  if (!is.null(item_ids)) {
    if (!is.character(item_ids) || is.null(names(item_ids)) ||
        anyDuplicated(names(item_ids)) ||
        any(!names(item_ids) %in% c("greyscale", "dark", "color")) ||
        anyNA(item_ids) || any(!grepl("^[A-Fa-f0-9]{32}$", item_ids)))
      stop("item_ids must be named ArcGIS IDs, e.g. c(color = '32_character_id').", call. = FALSE)
    for (i in seq_along(catalog$basemaps)) {
      key <- catalog$basemaps[[i]]$style
      if (key %in% names(item_ids)) catalog$basemaps[[i]]$item_id <- unname(item_ids[[key]])
    }
  }
  # Fetch and validate all three before writing anything.
  catalog$basemaps <- lapply(catalog$basemaps, .live_entry, timeout = timeout)
  catalog$retrieved_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  .dot_catalog(catalog)
  jsonlite::write_json(catalog, file, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(normalizePath(file, winslash = "/", mustWork = TRUE))
}
