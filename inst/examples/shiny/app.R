library(shiny)
library(leaflet)
library(IowaDOTbasemaps)

ui <- fluidPage(
  titlePanel("IowaDOTbasemaps: Shiny regression example"),
  sidebarLayout(
    sidebarPanel(
      selectInput("provider", "Basemap", c(
        "DOT greyscale" = "greyscale", "DOT dark greyscale" = "dark",
        "DOT color" = "color", "CARTO Positron" = "carto")),
      checkboxInput("labels", "DOT labels", TRUE),
      actionButton("update", "Update incidents through leafletProxy"),
      actionButton("clear_base", "Clear basemap only"),
      actionButton("restore", "Restore selected basemap"),
      helpText("Click the orange incident marker and magenta line. Switch maps rapidly,",
        "pan/zoom, and clear the basemap: incidents should stay visible and clickable."),
      helpText("CARTO reads CARTO_API_KEY from the server environment. No key is bundled."),
      verbatimTextOutput("status"),
      verbatimTextOutput("clicked")
    ),
    mainPanel(tabsetPanel(
      tabPanel("Primary map", leafletOutput("map", height = 600)),
      tabPanel("Second map / hidden-tab test", leafletOutput("second", height = 600))
    ))
  )
)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() |>
      addIowaBasemap("greyscale", layerId = "background", group = "Basemap") |>
      setView(-93.62, 42.02, 12) |>
      addCircleMarkers(lng = -93.62, lat = 42.02, radius = 12,
        color = "#a33a00", fillColor = "#ffb000", fillOpacity = 1,
        layerId = "incident", group = "Incidents", popup = "Initial incident") |>
      addPolylines(lng = c(-93.65, -93.60), lat = c(42.015, 42.015),
        color = "#df007e", weight = 7, layerId = "road", group = "Incidents",
        popup = "Initial incident line")
  })
  output$second <- renderLeaflet({
    leaflet() |> addIowaBasemap("color") |> setView(-93.6, 42, 8) |>
      addCircleMarkers(lng = -93.6, lat = 42, radius = 12, color = "red")
  })
  change_basemap <- function() {
    if (input$provider == "carto" && !nzchar(Sys.getenv("CARTO_API_KEY"))) {
      showNotification("Set CARTO_API_KEY and restart R before choosing CARTO.", type = "error")
      return(invisible(NULL))
    }
    proxy <- leafletProxy("map", session)
    if (input$provider == "carto") {
      addCartoBasemap(proxy, layerId = "background", group = "Basemap")
    } else {
      addIowaBasemap(proxy, style = input$provider, labels = input$labels,
        layerId = "background", group = "Basemap")
    }
    # Reusing the same layerId replaces only that IowaDOTbasemaps basemap.
  }
  observeEvent(list(input$provider, input$labels), change_basemap(), ignoreInit = TRUE)
  observeEvent(input$restore, change_basemap())
  observeEvent(input$clear_base, clearBasemaps(leafletProxy("map", session)))
  observeEvent(input$update, {
    latitude <- 42.02 + (input$update %% 3) * 0.005
    leafletProxy("map", session) |>
      clearGroup("Incidents") |>
      addCircleMarkers(lng = -93.62, lat = latitude, radius = 12,
        color = "#a33a00", fillColor = "#ffb000", fillOpacity = 1,
        layerId = "incident", group = "Incidents",
        popup = paste("Proxy incident update", input$update)) |>
      addPolylines(lng = c(-93.65, -93.60), lat = c(latitude - 0.005, latitude - 0.005),
        color = "#df007e", weight = 7, layerId = "road", group = "Incidents",
        popup = paste("Proxy line update", input$update))
  })
  output$status <- renderPrint(input$map_basemap_status)
  output$clicked <- renderPrint(list(marker = input$map_marker_click, line = input$map_shape_click))
}

shinyApp(ui, server)
