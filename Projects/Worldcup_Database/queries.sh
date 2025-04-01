#! /bin/bash

PSQL_USER="freecodecamp"
if [[ ! -z $1 ]]; then
  PSQL_USER=$1
fi
PSQL="psql --username=$PSQL_USER --dbname=worldcup --no-align --tuples-only -c"

# Do not change code above this line. Use the PSQL variable above to query your database.

echo -e "\nTotal number of goals in all games from winning teams:"
echo "$($PSQL "SELECT SUM(winner_goals) FROM games")"

echo -e "\nTotal number of goals in all games from both teams combined:"
echo "$($PSQL "SELECT SUM(winner_goals + opponent_goals) FROM games")"

echo -e "\nAverage number of goals in all games from the winning teams:"
echo "$($PSQL "SELECT avg(winner_goals) FROM games")"

echo -e "\nAverage number of goals in all games from the winning teams rounded to two decimal places:"
echo  "$($PSQL "SELECT round(AVG(winner_goals), 2) FROM games")"

echo -e "\nAverage number of goals in all games from both teams:"
echo "$($PSQL "SELECT avg(winner_goals + opponent_goals) FROM games")"

echo -e "\nMost goals scored in a single game by one team:"
echo "$($PSQL "SELECT max(winner_goals) FROM games")"

echo -e "\nNumber of games where the winning team scored more than two goals:"
echo "$($PSQL "SELECT count(*) FROM games where winner_goals > 2")"

echo -e "\nWinner of the 2018 tournament team name:"
# echo "$($PSQL "SELECT name FROM teams where team_id=(select winner_id from games where round='Final' and year=2018)")"
echo "$($PSQL "SELECT name from games left join teams on games.winner_id=teams.team_id where round='Final' and year=2018")"

echo -e "\nList of teams who played in the 2014 'Eighth-Final' round:"
echo "$($PSQL "select distinct(name) from teams as x left join games as y on x.team_id=y.winner_id left join games as z on x.team_id=z.opponent_id where (y.round='Eighth-Final' or z.round='Eighth-Final') and (y.year=2014 or z.year=2014);")"

echo -e "\nList of unique winning team names in the whole data set:"
echo "$($PSQL "select distinct(name) from teams as x full join games as y on y.winner_id=x.team_id where team_id=winner_id order by name;")"

echo -e "\nYear and team name of all the champions:"
echo "$($PSQL "select year, name from games as x full join teams as y on x.winner_id=y.team_id where round='Final' order by year;")"

echo -e "\nList of teams that start with 'Co':"
echo "$($PSQL "select name from teams where name like 'Co%';")"
