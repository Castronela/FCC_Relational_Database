#! /bin/bash

PSQL_USER="freecodecamp"
if [[ ! -z $1  && $1 != "test" ]]; then
  PSQL_USER=$1
fi

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=$PSQL_USER --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

$PSQL "truncate table games, teams;"

cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT W_GOALS O_GOALS; do
  # skip column labels
  if [[ $YEAR = year ]]; then
    continue
  fi

  # check if winner is in teams list
  if [[ $($PSQL "select name from teams where name='$WINNER';") != $WINNER ]]; then
    # if not, add winner to teams list
    $PSQL "insert into teams (name) values ('$WINNER');"
  fi
  # get winner id
  WINNER_ID="$($PSQL "select team_id from teams where name='$WINNER';")"

  # check if opponent is in teams list
  if [[ $($PSQL "select name from teams where name='$OPPONENT';") != $OPPONENT ]]; then
    # if not, add opponent to teams list
    $PSQL "insert into teams (name) values ('$OPPONENT');"
  fi
  # get opponent id
  OPPONENT_ID="$($PSQL "select team_id from teams where name='$OPPONENT';")"

  # insert game to table
  $PSQL "insert into games (year, round, winner_id, opponent_id, winner_goals, opponent_goals)\
         values ('$YEAR', '$ROUND', '$WINNER_ID', '$OPPONENT_ID', '$W_GOALS', '$O_GOALS');"
done
