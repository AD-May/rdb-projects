#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo Enter your username:
read USERNAME
GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")
CURRENT_GUESSES=0
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))

NUMBER_GAME() {
  echo $1
  if (( $CURRENT_GUESSES == 0 ))
  then
    echo -e "\nGuess the secret number between 1 and 1000:"
  fi
  read GUESS
  (( CURRENT_GUESSES++ ))
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    NUMBER_GAME "That is not an integer, guess again:"
  elif (( $GUESS > $RANDOM_NUMBER ))
  then
    NUMBER_GAME "It's lower than that, guess again:"
  elif (( $GUESS < $RANDOM_NUMBER ))
  then
    NUMBER_GAME "It's higher than that, guess again:"
  else
    echo "You guessed it in $CURRENT_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
    if [[ -z $BEST_GAME ]] || (( $CURRENT_GUESSES < BEST_GAME ))
    then
      UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game=$CURRENT_GUESSES WHERE username='$USERNAME'")
    fi
    if [[ -z $GAMES_PLAYED ]] 
    then
      INITIALIZE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=1 WHERE username='$USERNAME'")
    else
      UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED + 1 WHERE username='$USERNAME'")
    fi
    exit
  fi
}

USERNAME_QUERY=$($PSQL "SELECT * FROM users WHERE username='$USERNAME'")

if [[ -z $USERNAME_QUERY ]]
then
  INSERT_USERNAME=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  NUMBER_GAME "Welcome, $USERNAME! It looks like this is your first time here."
else
  NUMBER_GAME "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi