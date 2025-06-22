#!/bin/bash

PSQL="psql -X -U freecodecamp -d salon -t --no-align -c"

MAIN_MENU() {
  # welcome message
  echo -e "\n~~~~~ MY SALON ~~~~~\n"

  # optional message
  if [[ $1 ]]; then
    echo -e "$1"
  else
    echo -e "Welcome to My Salon, how can I help you?"
  fi

  # list services
  SERVICES=$($PSQL "SELECT service_id, name FROM services")
  echo "$SERVICES" | while IFS='|' read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  # get service ID
  read SERVICE_ID_SELECTED

  # validate input
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi

  # get service name
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  if [[ -z $SERVICE_NAME ]]; then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi
  SERVICE_NAME=$(echo "$SERVICE_NAME" | xargs)

  # get phone number
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # check if customer exists
  CUSTOMER_NAME_DB=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # if new customer, ask for name and insert
  if [[ -z $CUSTOMER_NAME_DB ]]; then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    $PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')"
  else
    CUSTOMER_NAME=$(echo "$CUSTOMER_NAME_DB" | xargs)
  fi

  # get customer ID
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # ask for appointment time
  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # insert appointment
  $PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')"

  # confirmation
  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

# start menu
MAIN_MENU