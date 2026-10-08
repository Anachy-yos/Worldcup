#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# start from empty tables so the script can be run again and again
echo $($PSQL "TRUNCATE TABLE games, teams")

# read games.csv once and build one VALUES list for each table
# ("< games.csv" instead of "cat games.csv |" so the variables survive the loop;
#  the "|| [[ -n ... ]]" keeps the last line even if the file has no trailing newline)
TEAM_VALUES=""
GAME_VALUES=""
while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS || [[ -n $OPPONENT_GOALS ]]
do
  if [[ $YEAR != "year" ]]
  then
    TEAM_VALUES+="('$WINNER'),('$OPPONENT'),"
    GAME_VALUES+="($YEAR,'$ROUND',(SELECT team_id FROM teams WHERE name='$WINNER'),(SELECT team_id FROM teams WHERE name='$OPPONENT'),$WINNER_GOALS,$OPPONENT_GOALS),"
  fi
done < games.csv

# one query for all teams (repeats are skipped because name is UNIQUE), one for all games
echo $($PSQL "INSERT INTO teams(name) VALUES ${TEAM_VALUES%,} ON CONFLICT (name) DO NOTHING")
echo $($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ${GAME_VALUES%,}")
