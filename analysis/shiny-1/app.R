# Edmonton Neighborhood Explorer
# Shiny app for visualizing and exploring Edmonton neighborhoods
# Data source: ellis_4_open_data table in global-data.sqlite

# ---- Load Libraries ----
library(shiny)
library(leaflet)
library(sf)
library(DBI)
library(RSQLite)
library(dplyr)

# ---- Load Data ----
# Connect to database (use path relative to project root)
db_path <- "../../data-private/derived/global-data.sqlite"
if (!file.exists(db_path)) {
  # If running from project root
  db_path <- "./data-private/derived/global-data.sqlite"
}
con <- dbConnect(SQLite(), db_path)

# Load neighborhood boundaries
neighborhoods_raw <- dbReadTable(con, "ellis_4_open_data")

# Load Square One Coffee locations
soc_locations_raw <- dbGetQuery(con, "
  SELECT name, formatted_address, lat, lng, rating, user_ratings_total, 
         business_status, phone, website
  FROM ellis_0_cafes 
  WHERE name LIKE '%Square One%' OR name LIKE '%Square 1%'
")

# Disconnect
dbDisconnect(con)

# Convert WKT geometry to sf object
neighborhoods_sf <- st_as_sf(
  neighborhoods_raw, 
  wkt = "the_geom", 
  crs = 4326
)

# Prepare data for dropdown (sort alphabetically by name)
neighborhood_choices <- neighborhoods_sf %>%
  arrange(name) %>%
  select(name, neighbourh) %>%
  st_drop_geometry()

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

# ---- UI ----
ui <- fluidPage(
  titlePanel("Edmonton Neighborhood Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectizeInput(
        inputId = "neighborhood",
        label = "Select Neighborhood:",
        choices = c("Select a neighborhood..." = "", 
                    setNames(neighborhood_choices$name, neighborhood_choices$name)),
        selected = "",
        options = list(
          placeholder = "Type to search...",
          maxOptions = 500
        )
      ),
      hr(),
      h4("Square One Coffee Locations"),
      helpText(paste0("Showing ", nrow(soc_locations_sf), " SOC locations (marked in blue)")),
      hr(),
      helpText("Select a neighborhood from the dropdown to highlight it on the map."),
      helpText("The map shows all", nrow(neighborhoods_sf), "neighborhoods in Greater Edmonton.")
    ),
    
    mainPanel(
      width = 9,
      leafletOutput("map", height = "700px")
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  
  # Base map with all neighborhoods and SOC locations
  output$map <- renderLeaflet({
    leaflet(neighborhoods_sf) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addPolygons(
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
          bringToFront = TRUE
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
      setView(lng = -113.4938, lat = 53.5461, zoom = 11)
  })
  
  # Highlight selected neighborhood
  observeEvent(input$neighborhood, {
    if (input$neighborhood != "") {
      # Get selected neighborhood geometry
      selected_neighborhood <- neighborhoods_sf %>%
        filter(name == input$neighborhood)
      
      # Update map with highlighted neighborhood
      leafletProxy("map") %>%
        clearGroup("highlighted") %>%
        addPolygons(
          data = selected_neighborhood,
          fillColor = "#ff6b6b",
          fillOpacity = 0.6,
          color = "#c92a2a",
          weight = 3,
          opacity = 1,
          group = "highlighted",
          label = ~name
        ) %>%
        fitBounds(
          lng1 = st_bbox(selected_neighborhood)["xmin"],
          lat1 = st_bbox(selected_neighborhood)["ymin"],
          lng2 = st_bbox(selected_neighborhood)["xmax"],
          lat2 = st_bbox(selected_neighborhood)["ymax"]
        )
    } else {
      # Clear highlight if no selection
      leafletProxy("map") %>%
        clearGroup("highlighted") %>%
        setView(lng = -113.4938, lat = 53.5461, zoom = 11)
    }
  })
}

# ---- Run App ----
shinyApp(ui = ui, server = server)
