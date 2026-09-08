library(leaflet)
library(IowaDOTbasemaps)

leaflet() |>
  addIowaBasemap("greyscale", group = "DOT greyscale") |>
  addIowaBasemap("dark", group = "DOT dark") |>
  addIowaBasemap("color", group = "DOT color") |>
  hideGroup(c("DOT dark", "DOT color")) |>
  addCircleMarkers(lng = -93.62, lat = 42.02, radius = 10,
    color = "red", group = "Incidents", popup = "Example incident") |>
  addLayersControl(baseGroups = c("DOT greyscale", "DOT dark", "DOT color"),
    overlayGroups = "Incidents", options = layersControlOptions(collapsed = FALSE)) |>
  setView(-93.62, 42.02, 10)
