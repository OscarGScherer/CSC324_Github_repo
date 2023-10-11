library(httr)
library(jsonlite)
library(ggplot2)
library(dplyr)

#### GENERAL FUNCTIONS USED BY server.R
####
####
####


##  api_call
#     Makes api call using the url and returns the content, returns null if there was error
#
#     arguments:
#       url: the url to make the call, assumed to be properly formatted
#
api_call <- function(url){
  request = GET(url)
  if(request$status_code != 200){
    request = NULL
  }else{
    request = fromJSON(rawToChar(request$content))
  }
}

##  name_to_puuid
#     Uses the api key and the region to search for the given player's puuid, a type of playerID used to make other api calls
#
#     arguments:
#       api_key:          the api_key used to make the request, needs to be valid
#       regionShorthand:  the name of the region where the player will be searched, e.g BR1, NA1, KR1
#       name:             the name of the player
#
name_to_puuid <- function(api_key, regionShorthand, name){
  url = paste0("https://", regionShorthand,".api.riotgames.com/lol/summoner/v4/summoners/by-name/",trimws(name),"?api_key=",api_key)
  request = api_call(url)
  request$puuid
}

##  puuid_to_matchIds
#     Get the ids of some number of previous matches played by a player
#
#     arguments:
#       api_key:          the api_key used to make the request, needs to be valid
#       region:           the name of the larger region where the matches were played, e.g americas
#       puuid:            the puuid of the player
#       num_Matches:      the number of matches to request from the server
#
puuid_to_matchIds <- function(api_key, region, puuid, num_matches){
  url = paste0("https://",region,".api.riotgames.com/lol/match/v5/matches/by-puuid/",puuid,"/ids?type=ranked&start=0&count=",num_matches,"&api_key=",api_key)
  request = api_call(url)
}

##  matchID_to_matchTimeline
#     Get the data of the timeline of a given matchId
#
#     arguments:
#       api_key:          the api_key used to make the request, needs to be valid
#       region:           the name of the larger region where the matches were played, e.g americas
#       matchID:          the id of the match to take the timeline from
#
matchID_to_matchTimeline <- function(api_key, region, matchId){
  url = paste0("https://",region,".api.riotgames.com/lol/match/v5/matches/",matchId,"/timeline?api_key=",api_key)
  request = api_call(url)
}

##  matchID_to_matchData
#     Get the data at the end of a match given a matchID
#
#     arguments:
#       api_key:          the api_key used to make the request, needs to be valid
#       region:           the name of the larger region where the matches were played, e.g americas
#       matchID:          the id of the match to take the data from
#
matchID_to_matchData <- function(api_key, region, matchId){
  url = paste0("https://",region,".api.riotgames.com/lol/match/v5/matches/",matchId,"?api_key=",api_key)
  request = api_call(url)
}

##  get_teammate_avg_stat
#     Get the performance of some player's average teammate, in a match, measured 
#     as the sum of some given stats divided by the sum of other given stats
#
#     arguments:
#       matchData:        the data of the match to compute the stats from
#       playerName:       the name of the player, used to determine their teammates
#       dividendStats:    list of string representing possible stats to be extracted 
#                         from the match, e.g. list("kills", "assists"). These stats
#                         will be summed and put on the dividend of the performance
#                         formula.
#       divisorStats:     list of string representing possible stats to be extracted 
#                         from the match, e.g. list("deaths"). These stats will be
#                         summed and put on the divisor part of the performance
#                         formula. If argument is null, the divisor will be 1.
#
get_teammate_avg_stat <- function(matchData, playerName, dividendStats, divisorStats){
  playerInd = match(playerName, matchData$info$participants$summonerName)
  if(playerInd > 5){
    teammateInd = (6:10)[-(playerInd - 5)]
  } else teammateInd = (1:5)[-playerInd]
  
  statDividend = rep(0,4)
  if(length(dividendStats)>0){
    for(i in 1 : length(dividendStats)){
      statDividend = statDividend + matchData$info$participants[[dividendStats[i]]][teammateInd]
    }
  }
  if(length(dividendStats) < 1) statDividend = rep(1,4)
  statDivisor = rep(0,4)
  if(length(divisorStats) > 0){
    for(i in 1 : length(divisorStats)){
      statDivisor = statDivisor + matchData$info$participants[[divisorStats[i]]][teammateInd]
    }
  }
  statDivisor[which(statDivisor %in% 0)] = 1
  
  teammateAvgStat = sum(statDividend / statDivisor)/4
}

##  get_enemy_avg_stat
#     Get the performance of the average enemy, in a match, measured 
#     as the sum of some given stats divided by the sum of other given stats
#
#     arguments:
#       matchData:        the data of the match to compute the stats from
#       playerName:       the name of the player, used to determine their enemies
#       dividendStats:    list of string representing possible stats to be extracted 
#                         from the match, e.g. list("kills", "assists"). These stats
#                         will be summed and put on the dividend of the performance
#                         formula.
#       divisorStats:     list of string representing possible stats to be extracted 
#                         from the match, e.g. list("deaths"). These stats will be
#                         summed and put on the divisor part of the performance
#                         formula. If argument is null, the divisor will be 1.
#
get_enemy_avg_stat <- function(matchData, playerName, dividendStats, divisorStats){
  playerInd = match(playerName, matchData$info$participants$summonerName)
  if(playerInd > 5){
    enemyInd = 1:5
  } else enemyInd = 6:10
  
  statDividend = rep(0,5)
  if(length(dividendStats)>0){
    for(i in 1 : length(dividendStats)){
      statDividend = statDividend + matchData$info$participants[[dividendStats[i]]][enemyInd]
    }
  }
  if(length(dividendStats) < 1) statDividend = rep(1,5)
  statDivisor = rep(0,5)
  if(length(divisorStats) > 0){
    for(i in 1 : length(divisorStats)){
      statDivisor = statDivisor + matchData$info$participants[[divisorStats[i]]][enemyInd]
    }
  }
  statDivisor[which(statDivisor %in% 0)] = 1
  
  enemyAvgStat = sum(statDividend / statDivisor)/5
}

##  get_player_stat
#     Get the performance of some players in a match, measured 
#     as the sum of some given stat divided by the sum of other given stats
#
#     arguments:
#       matchData:        the data of the match to compute the stats from
#       playerName:       the name of the player
#       dividendStats:    list of string representing possible stats to be extracted 
#                         from the match, e.g. list("kills", "assists"). These stats
#                         will be summed and put on the dividend of the performance
#                         formula.
#       divisorStats:     list of string representing possible stats to be extracted 
#                         from the match, e.g. list("deaths"). These stats will be
#                         summed and put on the divisor part of the performance
#                         formula. If argument is null, the divisor will be 1.
#
get_player_stat <- function(matchData, playerName, dividendStats, divisorStats){
  playerInd = match(playerName, matchData$info$participants$summonerName)
  statDividend = 0
  if(length(dividendStats)>0){
    for(i in 1 : length(dividendStats)){
      statDividend = statDividend + matchData$info$participants[[dividendStats[i]]][playerInd]
    }
  }
  if(length(dividendStats) < 1) statDividend = 1
  statDivisor = 0
  if(length(divisorStats) > 0){
    for(i in 1 : length(divisorStats)){
      statDivisor = statDivisor + matchData$info$participants[[divisorStats[i]]][playerInd]
    }
  }
  if(statDivisor <= 0) statDivisor = 1
  
  playerStat = statDividend / statDivisor
}

##  get_player_timelinestat
#     Get the timeline of the performance of a player in match on the given
#     statistic
#
#     arguments:
#       timeline:         the data of the timeline to compute the stats from
#       puuid:            the id of the player
#       stat:             stat to get from the timeline
#
get_player_timelinestat <- function(timeline, puuid, stat){
  playerInd = match(puuid, timeline$info$participants$puuid)
  timelineStat = timeline$info$frames$participantFrames[[playerInd]][[stat]]
}


##  get_enemy_avg_timelinestat
#     Get the timeline of the performance of the average enemy of the player id
#
#     arguments:
#       timeline:         the data of the timeline to compute the stats from
#       puuid:            the id of the player
#       stat:             stat to get from the timeline
#
get_enemy_avg_timelinestat <- function(timeline, puuid, stat){
  playerInd = match(puuid, timeline$info$participants$puuid)
  if(playerInd > 5){
    enemyInd = 1:5
  } else enemyInd = 6:10
  
  timelineStat = rep(0, length(timeline$info$frames$participantFrames[[1]][[stat]]))
  for(i in enemyInd){
    timelineStat = timelineStat + timeline$info$frames$participantFrames[[i]][[stat]]
  }
  timelineStat = timelineStat/5
}

##  get_teammate_avg_timelinestat
#     Get the timeline of the performance of the average teammate of the player id
#
#     arguments:
#       timeline:         the data of the timeline to compute the stats from
#       puuid:            the id of the player
#       stat:             stat to get from the timeline
#
get_teammate_avg_timelinestat <- function(timeline, puuid, stat){
  playerInd = match(puuid, timeline$info$participants$puuid)
  if(playerInd > 5){
    teammateInd = (6:10)[-(playerInd - 5)]
  } else teammateInd = (1:5)[-playerInd]
  
  timelineStat = rep(0,length(timeline$info$frames$participantFrames[[1]][[stat]]))
  for(i in teammateInd){
    timelineStat = timelineStat + timeline$info$frames$participantFrames[[i]][[stat]]
  }
  timelineStat = timelineStat/4
}


##  get_matchdata_list
#     Gets a list of matchdatas each from a list of matchIDs
#
#     arguments:
#       api_key:          the api_key used to make the request, needs to be valid
#       matches:          a list of matchIDs to get the matchdata from
#       region:           the name of the larger region where the matches were played, e.g americas
#
get_matchdata_list <- function(api_key, matches, region){
  numMatches = length(matches)
  matchDataList = list()
  for(i in 1 : numMatches){
    matchDataList[[i]] = matchID_to_matchData(api_key, region, matches[i])
  }
  matchDataList
}

##  get_matchtimeline_list
#     Gets a list of match timelines each from a list of matchIDs
#
#     arguments:
#       api_key:          the api_key used to make the request, needs to be valid
#       matches:          a list of matchIDs to get the timelines from
#       region:           the name of the larger region where the matches were played, e.g americas
#
get_matchtimeline_list <- function(api_key, matches, region){
  numMatches = length(matches)
  matchTimelineList = list()
  for(i in 1 : numMatches){
    matchTimelineList[[i]] = matchID_to_matchTimeline(api_key, region, matches[i])
  }
  matchTimelineList
}

##  generate_match_history_table
#     Generates a table contaning the date, victory/defeat, and the player's champion of
#     all given matches.
#
#     arguments:
#       matchDataList:    a list of matchdatas to make up the table
#       playerName:       the name of the player, used to find the winning team and the champ played
#
generate_match_history_table <- function(matchDataList, playerName){
  
  numMatches = length(matchDataList)
  indexes = seq(1, numMatches);
  
  table = data.frame(
    "Date" = rep("1970-01-01", numMatches),
    "Result" = rep("Defeat", numMatches),
    "Champion" = rep("Sion", numMatches),
    "Lane" = rep("Top", numMatches),
    "EnemyLaner" = rep("Sion", numMatches)
  )
  
  for(i in 1 : numMatches){
    matchI = matchDataList[[i]]
    
    table$Date[i] = as.character(as.POSIXct(matchI$info$gameCreation/1000, origin="1970-01-01"))
    table$Date[i] = gsub("\\..*", "", table$Date[i])
    
    playerInd = match(playerName, matchI$info$participants$summonerName)
    if((playerInd > 5 & matchI$info$teams$win[2]) | 
       (playerInd <= 5 & matchI$info$teams$win[1])) table$Result[i] = "Victory"
    
    table$Champion[i] = matchI$info$participants$championName[playerInd]
    if(table$Champion[i] == "MonkeyKing") table$Champion[i] = "Wukong"
    table$Champion[i] = paste0("played:", table$Champion[i])
    
    table$Lane[i] = matchI$info$participants$teamPosition[playerInd]
    
    enemyLaner = get_enemy_laner(matchI, playerName)[1]
    enemyLanerInd = match(enemyLaner, matchI$info$participants$summonerName)
    table$EnemyLaner[i] = matchI$info$participants$championName[enemyLanerInd]
    if(table$EnemyLaner[i] == "MonkeyKing") table$EnemyLaner[i] = "Wukong"
    table$EnemyLaner[i] = paste0("vs:", table$EnemyLaner[i])
  }
  
  table
  
}

##  get_enemy_laner
#     Gets the name and puuid of the enemy laner of the given player
#
#     arguments:
#       matchData:        the match data where to look for the enemy laner
#       playerName:       the name of the player, used to find their role and their enemy laner
#
get_enemy_laner <- function(matchData, playerName){
  playerInd = match(playerName, matchData$info$participants$summonerName)
  if(playerInd > 5){
    enemyInd = 1:5
  } else enemyInd = 6:10
  playerLane = matchData$info$participants$teamPosition[playerInd]
  enemyLanerIndex = match(playerLane, matchData$info$participants$teamPosition[enemyInd])
  if(playerInd < 6) enemyLanerIndex = enemyLanerIndex + 5
  c(matchData$info$participants$summonerName[enemyLanerIndex], matchData$info$participants$puuid[enemyLanerIndex])
}
