#!/bin/bash

PSQL_USER="freecodecamp"

PSQL() {
  psql -X -U "$PSQL_USER" -d "periodic_table" -A -t -c "$1"
}
MAIN() {
  if [[ ! $1 ]]; then
    echo "Please provide an element as an argument."
    exit 0
  fi
  ATOMIC_NUMBER=$(PSQL "select atomic_number from elements where atomic_number='$1';" 2> /dev/null)
  SYMBOL=$(PSQL "select symbol from elements where symbol='$1';" 2> /dev/null)
  NAME=$(PSQL "select name from elements where name='$1';" 2> /dev/null)
  if [[ ! -z $ATOMIC_NUMBER ]]; then
    SYMBOL=$(PSQL "select symbol from elements where atomic_number='$ATOMIC_NUMBER';")
    NAME=$(PSQL "select name from elements where atomic_number='$ATOMIC_NUMBER';")
  elif [[ ! -z $SYMBOL ]]; then
    ATOMIC_NUMBER=$(PSQL "select atomic_number from elements where symbol='$SYMBOL';")
    NAME=$(PSQL "select name from elements where symbol='$SYMBOL';")
  elif [[ ! -z $NAME ]]; then
    SYMBOL=$(PSQL "select symbol from elements where name='$NAME';")
    ATOMIC_NUMBER=$(PSQL "select atomic_number from elements where name='$NAME';")
  else
    echo "I could not find that element in the database."
    exit 0
  fi
  TYPE=$(PSQL "select type from properties full join types using (type_id) where atomic_number='$ATOMIC_NUMBER';")
  MASS=$(PSQL "select atomic_mass from properties where atomic_number='$ATOMIC_NUMBER';")
  MELT=$(PSQL "select melting_point_celsius from properties where atomic_number='$ATOMIC_NUMBER';")
  BOIL=$(PSQL "select boiling_point_celsius from properties where atomic_number='$ATOMIC_NUMBER';")
  echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $MASS amu. $NAME has a melting point of $MELT celsius and a boiling point of $BOIL celsius."
}

MAIN $@; exit 0