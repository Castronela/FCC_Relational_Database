#!/bin/bash

PSQL_USER="freecodecamp"

PSQL() {
  psql -U "$PSQL_USER" -d "number_guess_userbase" -A -t -c "$1"
}

MAIN() {
  BEST_GAME=
  echo "Enter your username:"
  read USERNAME
  IS_USERNAME=$(PSQL "select * from players where username = '$USERNAME';")
  if [[ -z $IS_USERNAME ]]; then
    PSQL "insert into players (username) values ('$USERNAME');" > /dev/null
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    GAMES_PLAYED=$(PSQL "select games_played from players where username = '$USERNAME';")
    BEST_GAME=$(PSQL "select best_game from players where username = '$USERNAME';")
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses. "
  fi

  CORRECT_NUMBER=$(GET_RANDOM_NUMBER)
  TRIES=0
  echo "Guess the secret number between 1 and 1000:"
  while [[ true ]]; do
    (( TRIES++ ))
    read GUESS
    if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
    elif [[ $GUESS -lt $CORRECT_NUMBER ]]; then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $CORRECT_NUMBER ]]; then
      echo "It's lower than that, guess again:"
    else
      break
    fi
  done
  echo "You guessed it in $TRIES tries. The secret number was $CORRECT_NUMBER. Nice job!"

  # increment games played
  PSQL "update players set games_played = (games_played + 1) where username ='$USERNAME';" > /dev/null
  # update best game if necessary
  if [[ -z $BEST_GAME || $TRIES -lt $BEST_GAME ]]; then
    PSQL "update players set best_game = $TRIES where username ='$USERNAME';" > /dev/null
  fi
}

GET_RANDOM_NUMBER() {
  echo $(( RANDOM % 1000 + 1 ))
}

MAIN $@; exit 0