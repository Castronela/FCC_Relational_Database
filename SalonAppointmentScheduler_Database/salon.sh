#!/bin/bash

echo -e "\n\n~~~~~ MY SALON ~~~~~\n"

SERVICES_FILE="services.csv"

PSQL_USER="david"
if [[ $1 ]]; then
  PSQL_USER=$1
fi

GET_SERVICES() {
  SERVICES=()
  while read -r SERVICE; do
    SERVICES+=("$SERVICE")
  done < "$SERVICES_FILE"
}
GET_SERVICES

PSQL() {
  psql -U $PSQL_USER -d salon --no-align --tuples-only -c "$1"
}

MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  else
    echo -e "\nWelcome to My Salon, how can I help you?"
  fi
  
  for i in "${!SERVICES[@]}"; do
    echo -e "$(( $i + 1 ))) ${SERVICES[$i]}"
  done
  
  read SERVICE_ID_SELECTED
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ || $SERVICE_ID_SELECTED -gt ${#SERVICES[@]} || $SERVICE_ID_SELECTED -lt 1 ]]; then
    MENU "I could not find that service. What would you like today?"
  else
    PROCESS_USER "$(( $SERVICE_ID_SELECTED - 1 ))"
  fi
}

PROCESS_USER() {
  local SERVICE_INDEX="$1"
  echo -e "\n What's your phone number?"
  read CUSTOMER_PHONE
  local NAME=$(PSQL "select name from customers where phone='$CUSTOMER_PHONE';")
  if [[ -z $NAME ]]; then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    PSQL "insert into customers (phone, name) values ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');" > /dev/null 2>&1
  fi
  PROCESS_APP "$CUSTOMER_NAME" "$SERVICE_INDEX"
}

PROCESS_APP () {
  local NAME="$1"
  local NAME_FORMAT=$(echo $NAME | sed -E 's/^ *| *$//')
  local SERVICE_INDEX="$2"
  echo -e "\nWhat time would you like your "${SERVICES[$SERVICE_INDEX]}", $NAME_FORMAT?"
  read SERVICE_TIME
  local CUSTOMER_ID=$(PSQL "select customer_id from customers where name='$NAME_FORMAT';")
  local SERVICE_ID=$(PSQL "select service_id from services where name='${SERVICES[$SERVICE_INDEX]}';")
  PSQL "insert into appointments (customer_id, service_id, time) values ('$CUSTOMER_ID', '$SERVICE_ID', '$SERVICE_TIME');" > /dev/null 2>&1
  echo -e "\nI have put you down for a "${SERVICES[$SERVICE_INDEX]}" at $SERVICE_TIME, $NAME_FORMAT."
}

MENU; exit 0