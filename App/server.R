#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source("apiFunctions.R")
library(httr)
library(jsonlite)
library(ggplot2)
library(dplyr)
library(shinyjs)
library(DT)

api_key = ""
gotMatchData = FALSE
currentNumMatches = 0
matchData = list()
matchTimelines = list()
matches = list()
region = "americas"
playerName = ""
playerPUUID = ""

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  ## Makes API all calls, creates the data table
  #     Monitors the search player button and makes the api calls when it is pressed
  #
  #
  #
  #
  observeEvent(input$apicall,{
    puuid = name_to_puuid(input$apiKey, input$region, input$playerName)
    
    if(is.null(puuid)){
      output$errorMessage <- renderText({
        "Player name not found"
      })
      output$history <- NULL
      output$table <- NULL
      gotMatchData <<- FALSE
      output$label1 <- NULL
      output$label2 <- NULL
      return()
    }
    
    api_key <<- input$apiKey
    
    output$errorMessage <- renderText({
      ""
    })
    
    gotMatchData <<- TRUE
    playerName <<- input$playerName
    playerPUUID <<- puuid
    currentNumMatches <<- input$numMatches
    regionShorthand <<- input$region
    region <<- "americas"
    
    matches <<- puuid_to_matchIds(api_key, region, puuid, currentNumMatches)
    matchData <<- get_matchdata_list(api_key, matches, region)
    matchTimelines <<- get_matchtimeline_list(api_key, matches, region)
    
    output$table <- DT::renderDataTable(datatable(generate_match_history_table(matchData, playerName), selection = 'single') %>% 
                                        formatStyle("Result", target = "row", backgroundColor = styleEqual(c("Defeat", "Victory"), c('#EE2C2C', '#76EE00'))),
                                        options = list(paging=FALSE, scrollX = TRUE), 
                                        rownames=TRUE, 
                                        filter = "top")
    
  })
  
  ## Generates the cross match plot
  #     Monitors various inputs and updates the cross match plot accordingly
  #
  #
  #
  #
  output$crossMatchPlot <- renderPlot(print({
    input$compareAgainst
    input$compareMethod
    input$dividendVariables
    input$divisorVariables
    input$table_rows_all
    input$table_rows_selected
    
    if(length(input$dividendVariables) < 1 || !gotMatchData){
      output$label1 <- NULL
      return(NULL)
    } 
    
    if(is.null(input$table_rows_all) || length(input$table_rows_all) < 1){
      filteredMatches = 1:currentNumMatches
    } else {
      filteredMatches = input$table_rows_all
    }
    
    matchIndexes = filteredMatches
    playerStats = rep(0, length(filteredMatches))
    otherStats = rep(0, length(filteredMatches))
    colors = rep("#76EE00", length(filteredMatches))
    
    for(i in 1 : length(filteredMatches)){
      matchI = matchData[[filteredMatches[i]]]
      
      playerStats[i] = get_player_stat(matchI, playerName, input$dividendVariables, input$divisorVariables) 
      
      switch(input$compareAgainst,
             "enemy laner" = {
               otherStats[i] = get_player_stat(matchI, get_enemy_laner(matchI, playerName)[1], input$dividendVariables, input$divisorVariables)
             },
             "average teammate" = {
               otherStats[i] = get_teammate_avg_stat(matchI, playerName, input$dividendVariables, input$divisorVariables)
             },
             "average enemy" = {
               otherStats[i] = get_enemy_avg_stat(matchI, playerName, input$dividendVariables, input$divisorVariables)
             },
             "no comparisson" = {
               otherStats[i] = 0
             }
      )
      
      playerInd = match(playerName, matchI$info$participants$summonerName)
      if((playerInd > 5 & matchI$info$teams$win[1]) |
         (playerInd <= 5 & matchI$info$teams$win[2])) colors[i] = "#EE2C2C"
    }
    
    if(length(input$table_rows_selected) == 1){
      selectedInd = match(input$table_rows_selected, filteredMatches)
      colors[selectedInd] = "blue"
    }
    
    switch(
      input$compareMethod,
      "player - other" = { 
        stats = playerStats - otherStats
        },
      "player / other" = { 
        stats = playerStats / otherStats
        },
      "player and other, side by side" = { 
        stats = c(rbind(playerStats, otherStats))
        matchIndexes = c(rbind(matchIndexes, matchIndexes))
      }
    )
    
    Title = gsub("other", input$compareAgainst, input$compareMethod)
    
    if(input$compareAgainst == "no comparisson"){
      stats = playerStats
      matchIndexes = filteredMatches
      Title = "player performace"
    }
    
    Xlabel = "match index"
    Ylabel = paste(sapply(input$dividendVariables, paste, collapse=""), collapse=" + ")
    if(length(input$divisorVariables) > 0) Ylabel = paste0("(", 
                                                          Ylabel, 
                                                          ") divided by (",
                                                          paste(sapply(input$divisorVariables, paste, collapse=""), collapse=" + "),
                                                          ")"
                                                          )
    
    statsData = data.frame("MatchInd" = matchIndexes,"Stats" = stats, "Groups" = factor(1:length(stats)))
    
    output$label1 <- renderText(Ylabel)
    
    ggplot(statsData, aes(x = factor(matchIndexes), y = Stats, group = Groups, fill = factor(matchIndexes))) + 
           geom_bar(stat="identity", position="dodge", width = 0.75, color = "black") + 
           scale_fill_manual(values = colors, guide = "none") +
           labs(title = Title) +
           xlab(Xlabel) +
           ylab(Ylabel)
    })
  )
  
  ## Generates the timeline plot
  #     Monitors various inputs and updates the timeline plot accordingly
  #
  #
  #
  #
  output$timelinePlot <- renderPlot(print({
    input$table_rows_all
    input$compareMethod
    input$compareAgainst
    input$timelineVariable
    input$table_rows_selected
    
    if(length(input$table_rows_selected) < 1 || 
       length(input$timelineVariable) < 1 ||
       !(input$table_rows_selected %in% input$table_rows_all)){
      output$label2 <- NULL
      return(NULL)
    } 
    timeline = matchTimelines[[input$table_rows_selected]]
    match = matchData[[input$table_rows_selected]]
    
    playerStats = get_player_timelinestat(timeline, playerPUUID, input$timelineVariable)
    otherStats = NULL
    
    switch(input$compareAgainst,
           "enemy laner" = {
             otherStats = get_player_timelinestat(timeline, get_enemy_laner(match, playerName)[2], input$timelineVariable)
           },
           "average teammate" = {
             otherStats = get_teammate_avg_timelinestat(timeline, playerPUUID, input$timelineVariable)
           },
           "average enemy" = {
             otherStats = get_enemy_avg_timelinestat(timeline, playerPUUID, input$timelineVariable)
           }
    )
    
    minutes = 1:length(playerStats)
    groups = rep("player", length(playerStats))
    
    switch(
      input$compareMethod,
      "player - other" = { 
        stats = playerStats - otherStats
      },
      "player / other" = { 
        stats = playerStats / otherStats
      },
      "player and other, side by side" = { 
        stats = c(rbind(playerStats, otherStats))
        minutes = c(rbind(minutes, minutes))
        groups = c(rbind(groups, rep("other", length(playerStats))))
      }
    )
    
    Title = input$compareMethod
    Title = gsub("other", input$compareAgainst, input$compareMethod)
    Xlabel = "Minutes"
    Ylabel = input$timelineVariable
    
    output$label2 <- renderText(Ylabel)
    
    if(input$compareAgainst == "no comparisson"){
      stats = playerStats
      Title = paste0("Player's ", input$timelineVariable, " per minute")
      minutes = 1:length(playerStats)
      groups = rep("player", length(playerStats))
    }
    
    df = data.frame("Stats" = stats, "Minutes" = minutes, "Group" = groups)
    
    ggplot(df, aes(x= Minutes, y = Stats, group = factor(Group))) +
      geom_line(aes(color=Group)) +
      xlab(Xlabel) +
      ylab(Ylabel) +
      labs(title = Title) +
      scale_color_manual(values = c("blue", "red"))
  }))
}
