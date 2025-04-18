#!/bin/bash
# Standard PostgreSQL Database Setup File

SCRIPT_HEADER="Students Database Setup"

PSQL_USER="david"
PSQL_DBASE="student"

SCRIPT_DIR=$(dirname "$(realpath "$0")")
SCRIPT_FILE_DATA_INIT="insert_data.sh"
SCRIPT_FILE_QUERY="student_info.sh"

TABLES=(
  "majors(
    major_id serial not null primary key,
    major varchar (50) not null
  )"
  "courses(
    course_id serial not null primary key,
    course varchar (100) not null
  )"
  "students(
    student_id serial not null primary key,
    first_name varchar (50) not null,
    last_name varchar (50) not null,
    major_id int references majors(major_id),
    gpa numeric (2,1)
  )"
  "majors_courses(
    major_id int references majors(major_id),
    course_id int references courses(course_id),
    primary key (major_id, course_id)
  )"
)

MENU=(
  "Database:    Create database and tables:         db_create; tables_create"
  ":            Remove database:                    db_remove"
  "Data:        Insert data:                        tables_init"
  ":            Remove data:                        tables_clear"
  "Dump:        Create dump file:                   dump_create"
  ":            Import dump file:                   dump_import"
  ":            Remove dump file:                   dump_remove"
  "Query:       Run query:                          query"
  "Exit:        Remove all and exit:                db_remove; dump_remove; exit 0"
  ":            Exit with no changes:               exit 0"
)

PSQL() {
  local DBASE=$PSQL_DBASE
  if [[ $2 ]]; then
    DBASE=$2
  fi
  psql -U $PSQL_USER -d $DBASE --no-align --tuples-only -c "$1"
}

GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
BLUE='\e[34m'

BOLD='\e[1m'
UNDERLINE='\033[4m'

RESET='\e[0m'

print_cmd_output() {
  printf "${GREEN}%s${RESET}\n" "$1"
}

print_cmd_error() {
  printf "${RED}%s${RESET}\n" "$1"
}

MAIN() {
  while [[ true ]]; do
    MENU_PRINT
    MENU_EXEC
  done
}

MENU_PRINT() {
  sleep 1
  printf "${YELLOW}${BOLD}${UNDERLINE}\n%s${RESET}\n" "Menu:"

  for i in "${!MENU[@]}"; do
    IFS=":" read -r SECTION_LABEL OPTION_LABEL _ <<< "${MENU[$i]}"
    if [[ ! -z $SECTION_LABEL ]]; then
      printf "\t${YELLOW}${BOLD}%s${RESET}\n" "$SECTION_LABEL"
    fi
    OPTION_LABEL=$(echo $OPTION_LABEL | sed -E 's/^ *//')
    printf "\t\t%-2d - ${YELLOW}%s${RESET}\n" "$(( $i + 1 ))" "$OPTION_LABEL"
  done

  printf "Option:"
}

MENU_EXEC() {
  read INPUT
  if [[ ! $INPUT =~ ^[0-9]+$ || $INPUT -gt ${#MENU[@]} || $INPUT -lt 1 ]]; then
    print_cmd_error "Option '$INPUT' doesn't exist."
    MAIN
  fi
  OPTION_SELECTED="${MENU[ (( $INPUT - 1 )) ]}"
  CMD=$(echo $OPTION_SELECTED | sed -E 's/^.*:.*: *(.*)$/\1/')
  eval $CMD
}

db_create() {
  local ERROR=$(PSQL "create database $PSQL_DBASE;" "postgres" 2>&1 > /dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Database '$PSQL_DBASE' created."
  else
    print_cmd_error "$ERROR"
  fi
}

db_remove() {
  local ERROR=$(PSQL "drop database $PSQL_DBASE;" "postgres" 2>&1 >/dev/null)
  if [[ -z $ERROR ]]; then
    print_cmd_output "Database '$PSQL_DBASE' removed."
  else
    print_cmd_error "$ERROR"
  fi
}

tables_create() {
  for i in "${!TABLES[@]}"; do
    # remove new lines
    local TABLE_FORMAT=$(echo ${TABLES[$i]} | sed -E 's/\n//')
    # create table
    local ERROR=$(PSQL "create table $TABLE_FORMAT;" 2>&1 > /dev/null)
    if [[ ! -z $ERROR ]]; then
      print_cmd_error "$ERROR"
    else
      # get table name
      local TABLE_NAME=$(echo "$TABLE_FORMAT" | sed -E 's/^(\w*)\(.*$/\1/')
      print_cmd_output "Table '$TABLE_NAME' created."
    fi
  done
}

tables_init() {
  if [[ -z $SCRIPT_FILE_DATA_INIT ]]; then
    print_cmd_error "Script file for data initialization not specified."
  elif [[ ! -f $SCRIPT_DIR/$SCRIPT_FILE_DATA_INIT ]]; then
    print_cmd_error "Script file '$SCRIPT_FILE_DATA_INIT' not found."
  else
      print_cmd_output "Inserting ..."
    local ERROR=$($SCRIPT_DIR/$SCRIPT_FILE_DATA_INIT $PSQL_USER 2>&1 >/dev/null)
    if [[ ! -z $ERROR ]]; then
      print_cmd_error "$ERROR"
    else
      print_cmd_output "Data inserted into tables."
    fi
  fi
}

tables_clear() {
  local TABLE_NAMES=""

  for i in "${!TABLES[@]}"; do
    # remove new lines
    local TABLE_FORMAT=$(echo ${TABLES[$i]} | sed -E 's/\n//')
    # get table name
    local TABLE_NAME=$(echo "$TABLE_FORMAT" | sed -E 's/^(\w*)\(.*$/\1/')
    # add table name to list of table names
    if [[ -z $TABLE_NAMES ]]; then
      TABLE_NAMES+="$TABLE_NAME"
    else
      TABLE_NAMES+=", $TABLE_NAME"
    fi
  done
  # truncate tables
  local ERROR=$(PSQL "truncate table $TABLE_NAMES;" 2>&1 > /dev/null)
  if [[ ! -z $ERROR ]]; then
    print_cmd_error "$ERROR"
  else
    print_cmd_output "Tables $TABLE_NAMES cleared."
  fi
}

dump_create() {
  if [[ $(psql -U $PSQL_USER -lqtA | cut -d \| -f 1 | grep -w $PSQL_DBASE) != $PSQL_DBASE ]]; then
    print_cmd_error "Database '$PSQL_DBASE' doesn't exit. Nothing to dump."
  elif [[ -f $SCRIPT_DIR/$PSQL_DBASE.sql ]]; then
    print_cmd_error "Dump file '$PSQL_DBASE.sql' found. Remove current dump file before creating."
  else
    pg_dump -cC --inserts -U $PSQL_USER $PSQL_DBASE > "$SCRIPT_DIR/$PSQL_DBASE.sql"
    print_cmd_output "Dump file '$PSQL_DBASE.sql' created"
  fi
}

dump_import() {
  if [[ ! -f $SCRIPT_DIR/$PSQL_DBASE.sql ]]; then
    print_cmd_error "Dump file '$PSQL_DBASE.sql' not found. Create dump file first."
  else
    local ERROR=$(psql -U $PSQL_USER -d $PSQL_DBASE < $SCRIPT_DIR/$PSQL_DBASE.sql 2>&1 >/dev/null)
    if [[ ! -z $ERROR ]]; then
      print_cmd_error "$ERROR"
    else
      print_cmd_output "Dump file '$PSQL_DBASE.sql' imported."
    fi   
  fi
}

dump_remove() {
  if [[ ! -f $SCRIPT_DIR/$PSQL_DBASE.sql ]]; then
    print_cmd_error "Dump file '$PSQL_DBASE.sql' not found. Nothing to remove"
  else
    rm $SCRIPT_DIR/$PSQL_DBASE.sql
    print_cmd_output "Dump file '$PSQL_DBASE.sql' removed."
  fi
}

query() {
  if [[ -z $SCRIPT_FILE_QUERY ]]; then
    print_cmd_error "Script file for query not specified."
  elif [[ ! -f $SCRIPT_DIR/$SCRIPT_FILE_QUERY ]]; then
    print_cmd_error "Script file '$SCRIPT_FILE_QUERY' not found."
  else
    print_cmd_output "$($SCRIPT_DIR/$SCRIPT_FILE_QUERY $PSQL_USER)"
  fi
}

printf "\n\n ${BLUE}${BOLD}%+30s${RESET} \n\n" "~~ $SCRIPT_HEADER ~~ "

MAIN; exit 0
