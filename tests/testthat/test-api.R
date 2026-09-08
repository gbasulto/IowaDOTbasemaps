test_that("DOT styles preserve the three authoritative Web Map IDs", {
  x <- dotBasemaps()
  expect_identical(x$style, c("greyscale", "dark", "color"))
  expect_identical(x$item_id, c("805a6f2de49841e8b390cd54d91e53ad",
    "ef58c25cf11b4a58a50e85e1e01b0bed", "77831691f545442e9bb57ed1e8ad7957"))
})

test_that("DOT uses registered methods and ships every declared dependency", {
  m <- addIowaBasemap(leaflet::leaflet(), "color", layerId = "base")
  call <- tail(m$x$calls, 1)[[1]]
  expect_identical(call$method, "IowaDOTbasemapsAddDOT")
  expect_identical(call$args[[1]]$layerId, "base")
  expect_identical(call$args[[1]]$source, "live")
  expect_false(call$args[[1]]$fallback)
  for (dep in IowaDOTbasemaps:::.dependencies()) {
    base <- system.file(dep$src$file, package = dep$package)
    if (!nzchar(base)) base <- dep$src$file
    expect_true(file.exists(file.path(base, dep$script)))
    if (length(dep$stylesheet)) expect_true(file.exists(file.path(base, dep$stylesheet)))
  }
})

test_that("basemap clearing does not append overlay clearing calls", {
  m <- leaflet::leaflet() |> leaflet::addCircleMarkers(lng = -93.6, lat = 42) |>
    addIowaBasemap() |> clearBasemaps()
  methods <- vapply(m$x$calls, `[[`, character(1), "method")
  expect_identical(tail(methods, 1), "IowaDOTbasemapsClear")
  expect_false(any(methods %in% c("clearShapes", "clearMarkers", "clearGroup")))
})

test_that("invalid options and missing keys fail before client serialization", {
  m <- leaflet::leaflet()
  expect_error(addCartoBasemap(m, api_key = ""), "CARTO_API_KEY")
  expect_error(addIowaBasemap(m, labels = NA), "TRUE or FALSE")
  expect_error(addIowaBasemap(m, opacity = 2), "between")
  expect_error(addIowaBasemap(m, timeout = 0), "positive")
  expect_error(addIowaBasemap(m, item_id = "not-an-id"), "32-character")
  expect_error(addIowaBasemap(m, item_id = strrep("a", 32), fallback = TRUE), "old bundled")
  expect_error(addIowaBasemap(list()), "leaflet")
  expect_error(refreshDOTBasemaps(tempfile(), item_ids = c(wrong = "x")), "named ArcGIS")
})

test_that("CARTO mode selection controls vector dependencies", {
  m <- addCartoBasemap(leaflet::leaflet(), api_key = "test-key", mode = "raster")
  expect_identical(tail(m$x$calls, 1)[[1]]$args[[1]]$mode, "raster")
  deps <- vapply(m$dependencies, `[[`, character(1), "name")
  expect_false("IowaDOTbasemaps-maplibre-gl" %in% deps)
})

test_that("proxy calls carry dependencies on the first invocation", {
  skip_if_not_installed("shiny")
  messages <- list()
  session <- list(ns = function(x) if (is.null(x)) "" else x,
    sendCustomMessage = function(type, message) messages[[length(messages) + 1L]] <<- list(type, message))
  proxy <- leaflet::leafletProxy("map", session = session, deferUntilFlush = FALSE)
  addIowaBasemap(proxy)
  expect_length(messages, 1)
  msg <- messages[[1]][[2]]
  expect_identical(msg$calls[[1]]$method, "IowaDOTbasemapsAddDOT")
  expect_true(length(msg$calls[[1]]$dependencies) >= 3L)
})

test_that("offline errors are not represented as unchanged catalogs", {
  local_mocked_bindings(.live_entry = function(...) stop("network unavailable"), .package = "IowaDOTbasemaps")
  x <- checkDOTBasemaps()
  expect_true(all(is.na(x$changed)))
  expect_true(all(x$status == "network unavailable"))
})

test_that("refresh does not overwrite without consent or write partial fetches", {
  destination <- tempfile(fileext = ".json")
  on.exit(unlink(destination))
  writeLines("keep-me", destination)
  expect_error(refreshDOTBasemaps(destination), "File exists")
  local_mocked_bindings(.live_entry = function(...) stop("offline"), .package = "IowaDOTbasemaps")
  expect_error(refreshDOTBasemaps(destination, overwrite = TRUE), "offline")
  expect_identical(readLines(destination), "keep-me")
})
