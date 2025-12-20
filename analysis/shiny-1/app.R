# Edmonton Neighborhood Explorer
# Shiny app for visualizing and exploring Edmonton neighborhoods
# Data source: ellis_4_open_data (neighborhoods), ellis_5_open_data (population)

# ---- Load Libraries ----
library(shiny)
library(leaflet)
library(sf)
library(DBI)
library(RSQLite)
library(dplyr)

# ---- Load Data Provisioning Functions ----
source("data-provisioning.R")

# ---- Load Data ----
# Connect to database (use path relative to project root)
db_path <- "../../data-private/derived/global-data.sqlite"
if (!file.exists(db_path)) {
  # If running from project root
  db_path <- "./data-private/derived/global-data.sqlite"
}

# Load neighborhoods with metrics using provisioning function
neighborhoods_sf <- provision_neighborhood_metrics(db_path)

# Get metric definitions
metrics <- get_metric_definitions()
metric_choices <- setNames(
  sapply(metrics, function(m) m$id),
  sapply(metrics, function(m) m$label)
)

# Load SOC locations
con <- dbConnect(SQLite(), db_path)

# Load Square One Coffee locations
soc_locations_raw <- dbGetQuery(con, "
  SELECT name, formatted_address, lat, lng, rating, user_ratings_total, 
         business_status, phone, website
  FROM ellis_0_cafes 
  WHERE name LIKE '%Square One%' OR name LIKE '%Square 1%'
")

# Disconnect
dbDisconnect(con)

# Convert SOC locations to sf object
soc_locations_sf <- st_as_sf(
  soc_locations_raw,
  coords = c("lng", "lat"),
  crs = 4326
)

# Create popup content for SOC markers
soc_locations_sf <- soc_locations_sf %>%
  mutate(
    popup_content = paste0(
      "<b>", name, "</b><br/>",
      formatted_address, "<br/>",
      "Rating: ", rating, " (", user_ratings_total, " reviews)<br/>",
      if_else(!is.na(phone), paste0("Phone: ", phone, "<br/>"), ""),
      if_else(!is.na(website), paste0("<a href='", website, "' target='_blank'>Website</a>"), "")
    )
  )

# Add Millwoods "coming soon" location (not yet in Google Places API)
millwoods_location <- data.frame(
  name = "Square 1 Coffee - Millwoods",
  formatted_address = "7319 29 Ave NW, Edmonton, AB",
  lat = 53.4603678,
  lng = -113.5016049,
  status = "Coming Soon"
)

millwoods_sf <- st_as_sf(
  millwoods_location,
  coords = c("lng", "lat"),
  crs = 4326
) %>%
  mutate(
    popup_content = paste0(
      "<b>", name, "</b><br/>",
      formatted_address, "<br/>",
      "<span style='color: #f59e0b; font-weight: bold;'>Status: Coming Soon</span>"
    )
  )

# ---- UI ----
ui <- fluidPage(
  titlePanel("Edmonton Neighborhood Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Neighborhood Coloring"),
      selectInput(
        inputId = "metric",
        label = "Color neighborhoods by:",
        choices = metric_choices,
        selected = "none"
      ),
      hr(),
      h4("Square One Coffee Locations"),
      helpText(paste0("Showing ", nrow(soc_locations_sf), " operational locations (blue)")),
      helpText("1 location coming soon (orange)"),
      hr(),
      helpText("Select a metric above to color neighborhoods."),
      helpText("Click neighborhoods or SOC markers for details.")
    ),
    
    mainPanel(
      width = 9,
      leafletOutput("map", height = "700px")
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  
  # Reactive metric selection
  selected_metric <- reactive({
    metrics[[which(sapply(metrics, function(m) m$id == input$metric))]]
  })
  
  # Base map with neighborhoods
  output$map <- renderLeaflet({
    leaflet(neighborhoods_sf) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = -113.4938, lat = 53.5461, zoom = 11)
  })
  
  # Update neighborhood coloring when metric changes
  observeEvent(input$metric, {
    metric <- selected_metric()
    
    if (metric$id == "none") {
      # Gray neighborhoods
      leafletProxy("map") %>%
        clearShapes() %>%
        clearControls() %>%
        addPolygons(
          data = neighborhoods_sf,
          fillColor = "#cccccc",
          fillOpacity = 0.3,
          color = "#666666",
          weight = 1,
          opacity = 0.7,
          layerId = ~name,
          label = ~name,
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#333333",
            fillOpacity = 0.5,
            bringToFront = FALSE
          )
        ) %>%
        addCircleMarkers(
          data = soc_locations_sf,
          radius = 8,
          color = "#2c5f8d",
          fillColor = "#3b82f6",
          fillOpacity = 0.9,
          weight = 2,
          opacity = 1,
          popup = ~popup_content,
          label = ~name,
          group = "soc_locations"
        ) %>%
        addCircleMarkers(
          data = millwoods_sf,
          radius = 8,
          color = "#d97706",
          fillColor = "#f59e0b",
          fillOpacity = 0.7,
          weight = 2,
          opacity = 1,
          popup = ~popup_content,
          label = ~name,
          group = "soc_coming_soon"
        )
    } else {
      # Choropleth coloring
      values <- neighborhoods_sf[[metric$column]]
      pal <- get_color_palette(values, metric$palette, metric$reverse)
      
      # Create popup content with metric value
      popup_content <- paste0(
        "<b>", neighborhoods_sf$name, "</b><br/>",
        metric$label, ": ",
        ifelse(
          is.na(values),
          "No data",
          format(round(values, 1), big.mark = ",")
        )
      )
      
      leafletProxy("map") %>%
        clearShapes() %>%
        clearControls() %>%
        addPolygons(
          data = neighborhoods_sf,
          fillColor = ~pal(values),
          fillOpacity = 0.7,
          color = "#666666",
          weight = 1,
          opacity = 0.7,
          layerId = ~name,
          popup = popup_content,
          label = ~name,
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#333333",
            fillOpacity = 0.9,
            bringToFront = FALSE
          )
        ) %>%
        addLegend(
          position = "bottomright",
          pal = pal,
          values = values,
          title = metric$label,
          opacity = 0.7
        ) %>%
        addCircleMarkers(
          data = soc_locations_sf,
          radius = 8,
          color = "#2c5f8d",
          fillColor = "#3b82f6",
          fillOpacity = 0.9,
          weight = 2,
          opacity = 1,
          popup = ~popup_content,
          label = ~name,
          group = "soc_locations"
        ) %>%
        addCircleMarkers(
          data = millwoods_sf,
          radius = 8,
          color = "#d97706",
          fillColor = "#f59e0b",
          fillOpacity = 0.7,
          weight = 2,
          opacity = 1,
          popup = ~popup_content,
          label = ~name,
          group = "soc_coming_soon"
        )
    }
  })
}

# ---- Run App ----
shinyApp(ui = ui, server = server)
