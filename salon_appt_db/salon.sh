#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -A -c"
echo -e "\n~~ MY SALON ~~"
echo -e "\nWelcome to My Salon, how can I help you?"

MAIN_MENU() {
  echo -e "\n1) cut\n2) color\n3) perm\n4) style\n5) trim"
  read SERVICE_ID_SELECTED
  case $SERVICE_ID_SELECTED in
    1) CHECKOUT_MENU $SERVICE_ID_SELECTED ;;
    2) CHECKOUT_MENU $SERVICE_ID_SELECTED ;;
    3) CHECKOUT_MENU $SERVICE_ID_SELECTED ;;
    4) CHECKOUT_MENU $SERVICE_ID_SELECTED ;;
    5) CHECKOUT_MENU $SERVICE_ID_SELECTED ;;
    *) MAIN_MENU ;;
  esac
}

EXIT() {
  echo -e "\nThank you for stopping in.\n"
}

CHECKOUT_MENU() {
  # store service id argument
  SERVICE_ID=$1
  # get phone number
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  # check if they entered anything
  if [[ -z $CUSTOMER_PHONE ]]
  then
    CHECKOUT_MENU "You must enter a valid phone-number."
  fi
  # check if phone number exists in db
  EXISTING_CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  if [[ -z $EXISTING_CUSTOMER_NAME ]]
  then
    # if phone entry doesn't exist, ask for name
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    if [[ -z $CUSTOMER_NAME ]]
    then
      CHECKOUT_MENU "You must enter a name."
    fi
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
  fi
  # get service name associated with service_id
  SERVICE_NAME_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID") 
  # get service time
  echo -e "\nWhat time would you like your $SERVICE_NAME_SELECTED, $CUSTOMER_NAME?"
  read SERVICE_TIME
  if [[ -z $SERVICE_TIME ]]
  then
    CHECKOUT_MENU "\nYou must enter a time."
  else 
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')")
    echo -e "\nI have put you down for a $SERVICE_NAME_SELECTED at $SERVICE_TIME, $CUSTOMER_NAME."
    EXIT
  fi
}
MAIN_MENU