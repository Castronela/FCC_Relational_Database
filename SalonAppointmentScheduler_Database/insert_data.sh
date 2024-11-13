#!/bin/bash

PSQL_USER=$1

SERVICES=(
  "cut"
  "color"
  "perm"
  "style"
  "trim"
)

PSQL() {
  psql -X -U $PSQL_USER -d salon --no-align --tuples-only -c "$1"
}

main() {
  for i in "${!SERVICES[@]}"; do
    PSQL "insert into services (name) values ('${SERVICES[$i]}');"
  done
}

main; exit 0