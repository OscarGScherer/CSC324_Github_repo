# CSC324 Github repo
Repo for my individual project for the FALL 2023 CSC324 course

## Documentation:

* **Data description + How was the data collected?**

  *All data is taken from the Riot Games API (https://developer.riotgames.com)
  Calls for the API are made live when the project is run*
  
* **Who are the users that this Shiny App was made for?**

  *The intended users are League of Legends players that wish to analyze their past performance.
  The user, being a League of Legends player, is expected to know basic statistic measurements of the game, like kills, assists, dragon kills, etc..*

* **What questions are you trying to answer?**

  *I intend to help players find out how they are performing relative to other players in their matches, accounting for every champion they used and measuring performance on every attribute available*

* **What needs improvement?**

  It would be interesting to explore match timeline data, instead of just using end of match data.
  It would be interesting to make the app more visualy appealing using custom graphics.

* **Sources or References**

  https://developer.riotgames.com

* **Description of the process used to gather and display data**

  *Calls to Riot's API are made using the "httr" library.
  All calls to Riot's API return json data, which can converted to data frames using the "jsonlite" library.
  First the user inputs their player name and their account region.
  Then the app gets the player's account ID, which is used to search for the ID's of the recent matches that they played.
  Using the list of matchID's, the app makes calls to retrieve the end of match data on each of the matchID, stored in a list.
  The resulting dataset is used to create a table, with which the user can filter matches by many factors (won/lost, champion played, date, enemy laner champion).
  The user can also select which statistics to display, along side the filtering, which are used to generate a barchart plot (using ggplot2).*

* **Description of encoding and mapping of the table.**

  **WHAT/HOW:**
  *The produced table shows the player's match history, putting each match on each row and giving their basic information for filtering purposes.
  The information displayed is the date and time the match was played, whether the player won or lost, the champion the player was playing as, the role the player was playing in, and
  the chamption the player was going up against (the enemy laner's champion).
  Each row is color coded to indicate victory or defeat, and each row is indexed in order of most recent to least recent match*

  **WHY:**
  *The table provides an easy way for the user to filter which matches to be displayed on the main barchart for instance, a user might want to look at their performance on only won matches
  or on only matches where they played a specific champion, or where they played against a specific champion
  The colors and the indexing help the user find a specific entry in the table on their respective barchart group*
  
* **Description of encoding and mapping of the barchart.**

  **WHAT/HOW:**
  *The produced barchart plots whatever sum of statistics the user selected, be that the number of "kills" they made, "goldEarned", etc...
  And it compares these selected statistics against some target the user chooses, the options being to compare against their "average teammate", "average enemy", their "enemy laner", or to not compare against anybody.
  If the user chooses to compare, they can select the method of comparisson, which can be by subracting, dividing, or just showing both player and comparisson target side by side.
  Each match in the bar chart is color coded to indicate if the player won or lost that match*

  **WHY:**
  *The barchart provides an interactive way to measure all aspects of performace a player might be interested in improving.
  The selectable comparrison target allows the user to focus on any type of improvement they prefer for instance, they might be looking to improve relative to their teammates, or relative to their enemy laner.
  The colors on the barchart provide make it easier for the user to reference one entry in the barchart plot to their respective entry in the table.*
  
