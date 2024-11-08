#!/bin/bash
# Script to set up database, tables and columns for Students
printf "\n\n%+30s\n\n\n" "~~ Student Database setup ~~"

SQL_USER="david"
if [[ ! -z $1 ]]; then
  SQL_USER=$1
fi

PSQL_MAIN="psql -X -U $SQL_USER -d postgres --no-align --tuples-only -c"
PSQL_STUD="psql -X -U $SQL_USER -d student --no-align --tuples-only -c"

main() {
  while [[ true ]]; do
    print_menu 
    read INPUT
    case "$INPUT" in
    1)
      create_database
      setup_all_tables;;
    2)
      init_data;;
    3)
      drop_database;;
    4)
      create_dump;;
    5)
      import_dump;;
    6)
      remove_dump;;
    7)
      show_info;;
    8)
      drop_database silent
      remove_dump silent
      exit 0;;
    9)
      exit 0;;
    esac
  done
}

print_menu() {
  local MENU=(
    "create and setup database"
    "insert data"
    "remove database"
    "create dump file"
    "import dump file"
    "remove dump file"
    "show query results"
    "remove all and exit"
    "exit"
  )
  for i in "${!MENU[@]}"; do
    printf "%+30s\t%d\n" "${MENU[$i]}" "$(( $i + 1 ))"
  done
}

create_database() {
  if [[ $(psql -U $SQL_USER -lqtA | cut -d \| -f 1 | grep -w student) != student ]]; then
    CREATE_DB_RESULT=$($PSQL_MAIN "create database student;")
    if [[ $CREATE_DB_RESULT = 'CREATE DATABASE' ]]; then
      echo "Database 'student' created."
    fi
  else
    echo "Database 'student' already exists"
  fi
}

drop_database() {
  if [[ $(psql -U $SQL_USER -lqtA | cut -d \| -f 1 | grep -w student) = student ]]; then
    DROP_DB_RESULT=$($PSQL_MAIN "drop database student;")
    if [[ $DROP_DB_RESULT = 'DROP DATABASE' ]]; then
      echo "Database 'student' removed."
    fi
  elif [[ $1 != silent ]]; then
    echo "Database 'student' not found. Nothing to remove."
  fi
}

setup_all_tables() {
  create_table_majors
  create_table_courses
  create_table_students
  create_table_majors_courses
}

create_table_majors() {
  CREATE_TBL_MAJ_RESULT=$($PSQL_STUD "create table majors(major_id serial not null primary key, major varchar (50) not null);")
  if [[ $CREATE_TBL_MAJ_RESULT = 'CREATE TABLE' ]]; then
    echo "Table 'majors' created."
  fi
}

create_table_courses() {
  CREATE_TBL_COU_RESULT=$($PSQL_STUD "create table courses(course_id serial not null primary key, course varchar (100) not null);")
  if [[ $CREATE_TBL_COU_RESULT = 'CREATE TABLE' ]]; then
    echo "Table 'courses' created."
  fi
}

create_table_students() {
  CREATE_TBL_STUD_RESULT=$($PSQL_STUD "create table students(student_id serial not null primary key, first_name varchar (50) not null, last_name varchar (50) not null, major_id int references majors(major_id), gpa numeric (2,1));")
  if [[ $CREATE_TBL_STUD_RESULT = 'CREATE TABLE' ]]; then
    echo "Table 'students' created."
  fi
}

create_table_majors_courses() {
  CREATE_TBL_MC_RESULT=$($PSQL_STUD "create table majors_courses(major_id int references majors(major_id), course_id int references courses(course_id), primary key (major_id, course_id));")
  if [[ $CREATE_TBL_MC_RESULT = 'CREATE TABLE' ]]; then
    echo "Table 'majors_courses' created."
  fi
}

create_dump() {
  if [[ $(psql -U $SQL_USER -lqtA | cut -d \| -f 1 | grep -w student) = student ]]; then
    pg_dump --clean --create --inserts -U $SQL_USER student > students.sql
    echo "Dump file created."
  else
    echo "Cannot create dump file. Database 'student' doesn't exist."
  fi
}

import_dump() {
  if [[ -f students.sql ]]; then
    if [[ $(psql -U $SQL_USER -lqtA | cut -d \| -f 1 | grep -w student) != student ]]; then
      psql -U $SQL_USER -d postgres < students.sql
      echo "Dump file imported."
    else
      echo "Database 'student' already exists. Remove database before importing."
    fi
  else
    echo "Cannot import dump. File 'students.sql' doesn't exist. Create dump file first."
  fi
}

remove_dump() {
  if [[ -f students.sql ]]; then
    rm students.sql
    echo "Dump file 'students.sql' removed."
  elif [[ $1 != silent ]]; then
    echo "Dump file 'students.sql' not found. Nothing to remove"
  fi
}

init_data() {
  if [[ $(psql -U $SQL_USER -lqtA | cut -d \| -f 1 | grep -w student) = student ]]; then
    ./insert_data.sh $SQL_USER
  else
    echo "Cannot insert data. Database 'student' doesn't exist."
  fi
}

show_info() {
  if [[ $(psql -U $SQL_USER -lqtA | cut -d \| -f 1 | grep -w student) = student ]]; then
    ./student_info.sh $SQL_USER
  else
    echo "Cannot run queries. Database 'student' doesn't exist."
  fi
}

main; exit

#echo $($PSQL "truncate students, majors, courses, majors_courses")