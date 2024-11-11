#!/bin/bash
# Set up databse, tables and columns
printf "\n%+30s\n\n" "~~ Bike Rental Shop Database Setup ~~"

PSQL_USER="freecodecamp"
PSQL_DBASE="bikes"
SCRIPT_DATA=
SCRIPT_QUERY=

GREEN='\e[32m'
RED='\e[31m'
RESET='\e[0m'

# if argument exists, replace SQL user with argument
if [[ ! -z $1 ]]; then
  PSQL_USER=$1
fi

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
    "Create Database and Columns, create_db;create_table_bikes;create_table_customers;create_table_rentals"
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
  local ERROR=$(PSQL "postgres" "create database $PSQL_DBASE;" 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Database '$PSQL_DBASE' created."
  else
    print_cmd_error "$ERROR"
  fi
}

remove_db() {
  local ERROR=$(PSQL "postgres" "drop database $PSQL_DBASE;" 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Database '$PSQL_DBASE' removed."
  else
    print_cmd_error "$ERROR"
  fi
}

create_table_bikes() {
  local RESULT=$(PSQL $PSQL_DBASE "create table bikes(
    bike_id serial not null primary key,
    type varchar (50) not null, 
    size int not null,
    available boolean not null default true
  );" 2>&1 > /dev/null)
  if [[ -z $RESULT ]]; then
    print_cmd_output "Table 'bikes' created."
  else
    print_cmd_error "$RESULT"
  fi
}

create_table_customers() {
  local RESULT=$(PSQL $PSQL_DBASE "create table customers(
    customer_id serial not null primary key,
    phone varchar (15) not null unique,
    name varchar (40) not null
  );" 2>&1 > /dev/null)
  if [[ -z $RESULT ]]; then
    print_cmd_output "Table 'customers' created."
  else
    print_cmd_error "$RESULT"
  fi
}

create_table_rentals() {
  local RESULT=$(PSQL $PSQL_DBASE "create table rentals(
    rental_id serial not null primary key,
    customer_id int not null references customers(customer_id),
    bike_id int not null references bikes(bike_id),
    date_rented date not null default now(),
    date_returned date
  );" 2>&1 > /dev/null)
  if [[ -z $RESULT ]]; then
    print_cmd_output "Table 'rentals' created."
  else
    print_cmd_error "$RESULT"
  fi
}


init_tables() {
  if [[ ! -z $SCRIPT_DATA ]]; then
    local ERROR=$($SCRIPT_DATA $PSQL_USER 2>&1 > /dev/null)
    if [[ -z $ERROR ]]; then
      print_cmd_output "Data inserted into tables."
    else
      print_cmd_error "$ERROR"
    fi
  else
    print_cmd_output "No insert data script."
  fi
  
}

clear_tables() {
  PSQL $PSQL_DBASE "truncate table bikes, customers, rentals;" > /dev/null
  print_cmd_output "Data removed from tables."
}

create_dump() {
  pg_dump -cC --inserts -U $PSQL_USER $PSQL_DBASE > "$PSQL_DBASE.sql"
  print_cmd_output "Dump file '$PSQL_DBASE.sql' created"
}

remove_dump() {
  if [[ -f "$PSQL_DBASE.sql" ]]; then
    rm "$PSQL_DBASE.sql"
    print_cmd_output "Dump file '$PSQL_DBASE.sql' removed."
  else
    print_cmd_output "Dump file '$PSQL_DBASE.sql' doesn't exist. Nothing to remove."
  fi
}

run_query() {
  if [[ ! -z $SCRIPT_QUERY ]]; then
    $SCRIPT_QUERY $PSQL_USER
  else
    print_cmd_output "No query script."
  fi
}

main; exit 0