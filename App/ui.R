library(DT)
library(shiny)
library(shinyjs)
source("uiOptions.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  useShinyjs(),
  
  # Application title
  titlePanel("League Match History"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    
    sidebarPanel(
      
      width = 3,
      
      h3("Player Search"),
       
      textInput(inputId = "apiKey", label = "API Key", value = "RGAPI-70b7664b-46f7-459b-becd-1875d1d28ccf"),
      
      textInput(inputId = "playerName", label = "Player name", value = "DYLE0"),
    
      selectInput(
        inputId = "region",
        "Region",
        c("BR1", "NA1"),
        selected = NULL,
        multiple = FALSE,
        selectize = TRUE,
        width = NULL,
        size = NULL
      ),
      
      sliderInput("numMatches", 1, 30, 1, label = "Number of matches", value = 5),
      
      actionButton("apicall", "Search Player"),
      
      h3("Select End of Match Variables"),
      
      selectInput(
        "dividendVariables", "Sum these variables:", matchEndVars,
        multiple = TRUE
      ),
      
      selectInput(
        "divisorVariables", "And divide by the sum of:", matchEndVars,
        multiple = TRUE
      ),
      
      selectInput(
        "compareAgainst", "Compare against other:", c("no comparisson", "enemy laner", "average teammate", "average enemy"),
        multiple = FALSE
      ),
      
      selectInput(
        "compareMethod", "Comparisson method", c("player - other", "player / other", "player and other, side by side"),
        multiple = FALSE,
        selected = "player - other"
      ),
      
      h3("Select Timeline Variables"),
      
      selectInput(
        "timelineVariable", "Select variable:", matchTimelineVars,
        multiple = FALSE
      ),
    ),
    
    
    
    # Show a plot of the generated distribution
    mainPanel(
      textOutput("errorMessage"),
      DT::dataTableOutput("table"),
      fluidRow(
        splitLayout(cellWidths = c("50%", "50%"), 
                    textOutput("label1"), 
                    textOutput("label2"))
        ),
      tags$head(tags$style("#label1{color: black;font-size: 20px;font-style: bold;}")),
      tags$head(tags$style("#label2{color: black;font-size: 20px;font-style: bold;}")),
      fluidRow(
        splitLayout(cellWidths = c("50%", "50%"), plotOutput("crossMatchPlot"), plotOutput("timelinePlot"))
      )
    )
  )
)
