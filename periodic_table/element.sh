#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"
# check if script started with parameter
if [[ ! $1 ]] 
then
  echo "Please provide an element as an argument."
else
  INPUT="$1"
  # get element info
  ATOMIC_NUMBER=""
  SYMBOL=""
  ELEMENT_NAME=""
  # check if input was an atomic number
  if [[ "$INPUT" =~ ^[0-9]+$ ]] && (($INPUT <= 10))
  then
    ATOMIC_NUMBER=$INPUT
    SYMBOL=$($PSQL "SELECT symbol FROM elements WHERE atomic_number=$ATOMIC_NUMBER")
    ELEMENT_NAME=$($PSQL "SELECT name FROM elements WHERE atomic_number=$ATOMIC_NUMBER")
    TYPE=$($PSQL "SELECT type FROM types INNER JOIN properties USING(type_id) WHERE atomic_number=$ATOMIC_NUMBER")
    ATOMIC_MASS=$($PSQL "SELECT atomic_mass FROM properties WHERE atomic_number=$ATOMIC_NUMBER")
    MELTING_POINT=$($PSQL "SELECT melting_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER")
    BOILING_POINT=$($PSQL "SELECT boiling_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER")
  # check if input was a symbol
  elif [[ "$INPUT" =~ ^[a-zA-Z]{1}$ ]] || [[ "$INPUT" =~ ^[a-zA-Z]{2}$ ]]
  then
    SYMBOL=$INPUT
    ATOMIC_NUMBER=$($PSQL "SELECT atomic_number FROM elements WHERE symbol='$SYMBOL'")
    ELEMENT_NAME=$($PSQL "SELECT name FROM elements WHERE symbol='$SYMBOL'")
    TYPE=$($PSQL "SELECT type FROM types INNER JOIN properties USING(type_id) INNER JOIN elements USING(atomic_number) WHERE symbol='$SYMBOL'")
    ATOMIC_MASS=$($PSQL "SELECT atomic_mass FROM properties INNER JOIN elements USING(atomic_number) WHERE symbol='$SYMBOL'")
    MELTING_POINT=$($PSQL "SELECT melting_point_celsius FROM properties INNER JOIN elements USING(atomic_number) WHERE symbol='$SYMBOL'")
    BOILING_POINT=$($PSQL "SELECT boiling_point_celsius FROM properties INNER JOIN elements USING(atomic_number) WHERE symbol='$SYMBOL'")
  # otherwise, it will be the element name
  else
    ELEMENT_NAME=$INPUT
    SYMBOL=$($PSQL "SELECT symbol FROM elements WHERE name='$ELEMENT_NAME'")
    ATOMIC_NUMBER=$($PSQL "SELECT atomic_number FROM elements WHERE name='$ELEMENT_NAME'")
    TYPE=$($PSQL "SELECT type FROM types INNER JOIN properties USING(type_id) INNER JOIN elements USING(atomic_number) WHERE name='$ELEMENT_NAME'")
    ATOMIC_MASS=$($PSQL "SELECT atomic_mass FROM properties INNER JOIN elements USING(atomic_number) WHERE name='$ELEMENT_NAME'")
    MELTING_POINT=$($PSQL "SELECT melting_point_celsius FROM properties INNER JOIN elements USING(atomic_number) WHERE name='$ELEMENT_NAME'")
    BOILING_POINT=$($PSQL "SELECT boiling_point_celsius FROM properties INNER JOIN elements USING(atomic_number) WHERE name='$ELEMENT_NAME'")
  fi
  # if values not found in database
  if [[ -z $ATOMIC_NUMBER || -z $SYMBOL || -z $ELEMENT_NAME ]]
  then
    echo I could not find that element in the database.
  else
    echo "The element with atomic number $ATOMIC_NUMBER is $ELEMENT_NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $ELEMENT_NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
  fi
fi