#!/bin/bash
# Set up databse, tables and columns
printf "\n%+30s\n\n" "~~ Worldcup Database Setup ~~"

GREEN='\e[32m'
RED='\e[31m'
RESET='\e[0m'

PSQL_USER="freecodecamp"
if [[ ! -z $1 ]]; then
  PSQL_USER=$1
fi
DBASE="worldcup"
PSQL() {
  psql -U $PSQL_USER -d $1 --no-align --tuples-only -c "$2"
}

main() {
  while [[ true ]]; do
    display_menu
    echo -n "Option:"
    read INPUT
    OPTION="${MENU[ (( $INPUT - 1 )) ]}"
    IFS="," read -r _ CMD <<< "$OPTION"
    eval "$CMD"
  done
}

display_menu() {
  I=0
  echo
  menu_database
  menu_data
  menu_dump
  menu_query
  menu_exit
  MENU=(
    "${MENU_DB[@]}"
    "${MENU_DATA[@]}"
    "${MENU_DUMP[@]}"
    "${MENU_QUERY[@]}"
    "${MENU_EXIT[@]}"
  )
}

menu_database() {
  print_title "Database:"
  MENU_DB=(
    "Create Database and Columns, create_db;create_table_teams;create_table_games"
    "Remove Database, remove_db"
  )
  print_arr "${MENU_DB[@]}" 
}

menu_data() {
  print_title "Data:"
  MENU_DATA=(
    "Insert data, init_tables"
    "Remove data, clear_tables"
  )
  print_arr "${MENU_DATA[@]}" 
}

menu_dump() {
  print_title "Dump file:"
  MENU_DUMP=(
    "Create dump file, create_dump"
    "Remove dump file, remove_dump"
  )
  print_arr "${MENU_DUMP[@]}" 
}

menu_query() {
  print_title "Query:"
  MENU_QUERY=(
    "Query tables, run_query"
  )
  print_arr "${MENU_QUERY[@]}" 
}

menu_exit() {
  print_title "Exit:"
  MENU_EXIT=(
    "Remove all and exit, remove_db; remove_dump; exit 0"
    "Exit, exit 0"
  )
  print_arr "${MENU_EXIT[@]}" 
}

print_arr() {
  ARR=("$@")
  for i in "${!ARR[@]}"; do
    IFS="," read -r LABEL _ <<< "${ARR[$i]}"
    printf "|\t\t\t%d - %s\n" "$(( $I + 1 ))" "$LABEL"
    (( I++ ))
  done
}

print_title() {
  printf "| %s\n" "$1"
}

print_cmd_output() {
  printf "${GREEN}%s${RESET}\n" "$1"
}

print_cmd_error() {
  printf "${RED}%s${RESET}\n" "$1"
}



create_db() {
  local ERROR=$(PSQL "postgres" "create database $DBASE;" 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Database '$DBASE' created."
  else
    print_cmd_error "$ERROR"
  fi
}

remove_db() {
  local ERROR=$(PSQL "postgres" "drop database $DBASE;" 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Database '$DBASE' removed."
  else
    print_cmd_error "$ERROR"
  fi
}

create_table_teams() {
  local RESULT=$(PSQL $DBASE "create table teams(
    team_id serial not null primary key,
    name text unique not null  
  );" 2>&1 > /dev/null)
  if [[ -z $RESULT ]]; then
    print_cmd_output "Table 'teams' created."
  else
    print_cmd_error "$RESULT"
  fi
}

create_table_games() {
  local ERROR=$(PSQL $DBASE "create table games(
    game_id serial not null primary key,
    year int not null,
    round varchar not null,
    winner_id int not null references teams(team_id),
    opponent_id int not null references teams(team_id),
    winner_goals int not null,
    opponent_goals int not null
  );" 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Table 'games' created."
  else
    print_cmd_error "$ERROR"
  fi
}

init_tables() {
  local ERROR=$(./insert_data.sh $PSQL_USER 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Data inserted into tables."
  else
    print_cmd_error "$ERROR"
  fi
}

clear_tables() {
  PSQL $DBASE "truncate table games, teams;" > /dev/null
  print_cmd_output "Data removed from tables."
}

create_dump() {
  pg_dump -cC --inserts -U $PSQL_USER $DBASE > "$DBASE.sql"
  print_cmd_output "Dump file '$DBASE.sql' created"
}

remove_dump() {
  if [[ -f "$DBASE.sql" ]]; then
    rm "$DBASE.sql"
    print_cmd_output "Dump file '$DBASE.sql' removed."
  else
    print_cmd_output "Dump file '$DBASE.sql' doesn't exist. Nothing to remove."
  fi
}

run_query() {
  ./queries.sh $PSQL_USER
}

main; exit 0