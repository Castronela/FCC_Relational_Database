#!/bin/bash

# Tables:
# bikes: bike_id serial not null primary key, type varchar (50) not null, size int not null, available boolean not null default true
# customers: customer_id serial not null primary key, phone varchar (15) not null unique, name varchar (40) not null
# rentals: rental_id serial not null primary key, customer_id int not null references customers(customer_id), bike_id int not null references bikes(bike_id), date_rented date not null default now(), date_returned date

PSQL_USER="freecodecamp"
if [[ $1 ]]; then
	PSQL_USER=$1
fi
PSQL="psql -X -U $PSQL_USER --dbname=bikes --tuples-only -c"

echo -e "\n~~~~~ Bike Rental Shop ~~~~~\n"

MAIN_MENU() {
	if [[ $1 ]]; then
		echo -e "\n$1"
	fi
	echo "How may I help you?"
	echo "
1. Rent a bike
2. Return a bike
3. Exit"

read MAIN_MENU_SELECTION
case $MAIN_MENU_SELECTION in
	1) RENT_MENU ;;
	2) RETURN_MENU ;;
	3) EXIT ;;
	*) MAIN_MENU "Please enter a valid option." ;;
esac
}

RENT_MENU() {
	# get available bikes
	AVAILABLE_BIKES=$($PSQL "select bike_id, type, size from bikes where available=true order by bike_id;")
	# if no bikes available
	if [[ -z $AVAILABLE_BIKES ]]; then
		# send to main menu
		MAIN_MENU "Sorry, we don't have any bikes available right now."
	else
		# display available bikes
		echo -e "\nHere are the bikes we have available:"
		echo "$AVAILABLE_BIKES" | while read BIKE_ID BAR TYPE BAR SIZE; do
			echo "$BIKE_ID) $SIZE\" $TYPE Bike"
		done
		# ask for bike to rent
		echo -e "\nWhich one would you like to rent?"
		read BIKE_ID_TO_RENT
		# if input is not a number
		if [[ ! $BIKE_ID_TO_RENT =~ ^[0-9]+$ ]]; then
			# send to main menu
			MAIN_MENU "That is not a valid bike number."
		else
			# get bike availability
			BIKE_AVAILABILITY=$($PSQL "select available from bikes where bike_id='$BIKE_ID_TO_RENT' and available=true;")
			# if not available
			if [[ -z $BIKE_AVAILABILITY ]]; then
				# send to main menu
				MAIN_MENU "That bike is not available."
			else
				# get customer info
				echo -e "\nWhat's your phone number?"
				read PHONE_NUMBER
				CUSTOMER_NAME=$($PSQL "select name from customers where phone='$PHONE_NUMBER';")
				# if customer doesn't exist
				if [[ -z $CUSTOMER_NAME ]]; then
					# get new customer name
					echo -e "\nWhat's your name?"
					read CUSTOMER_NAME
					# insert new customer
					INSERT_CUSTOMER_RESULT=$($PSQL "insert into customers (phone, name) values ('$PHONE_NUMBER', '$CUSTOMER_NAME')")
				fi
				# get customer_id
				CUSTOMER_ID=$($PSQL "select customer_id from customers where phone='$PHONE_NUMBER';")
				# insert bike rental
				INSERT_RENTAL_RESULT=$($PSQL "insert into rentals (customer_id, bike_id) values ('$CUSTOMER_ID', '$BIKE_ID_TO_RENT');")
				# set bike availability to false
				SET_TO_FALSE_RESULT=$($PSQL "update bikes set available=false where bike_id='$BIKE_ID_TO_RENT';")
				# get bike info
				BIKE_INFO=$($PSQL "select size, type from bikes where bike_id='$BIKE_ID_TO_RENT';")
				BIKE_INFO_FORMATTED=$(echo $BIKE_INFO | sed 's/ |/"/')
				# send to main menu
				MAIN_MENU "I have put you down for the $BIKE_INFO_FORMATTED Bike, $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')."
			fi				
		fi
	fi

}

RETURN_MENU() {
	# get customer info
	echo -e "\nWhat's your phone number?"
	read PHONE_NUMBER
	CUSTOMER_ID=$($PSQL "select customer_id from customers where phone='$PHONE_NUMBER';")
	# if not found
	if [[ -z $CUSTOMER_ID ]]; then
		# send to main menu
		MAIN_MENU "I could not find a record for that phone number."
	else
		# get customer's rentals
		CUSTOMER_RENTALS=$($PSQL "select bike_id, type, size from bikes inner join rentals using (bike_id) inner join customers using (customer_id) where phone='$PHONE_NUMBER' and date_returned is null order by bike_id;")
		# if no rentals
		if [[ -z $CUSTOMER_RENTALS ]]; then
			# send to main menu
			MAIN_MENU "You do not have any bikes rented."
		else
			# display rented bikes
			echo -e "\nHere are your rentals:"
			echo "$CUSTOMER_RENTALS" | while read BIKE_ID BAR TYPE BAR SIZE; do
				echo "$BIKE_ID) $SIZE\" $TYPE Bike"
			done
			# ask for bike to return
			echo -e "\nWhich one would you like to return?"
			read BIKE_ID_TO_RETURN
			# if not a number
			if [[ ! $BIKE_ID_TO_RETURN =~ ^[0-9]+$ ]]; then
				# send to main menu
				MAIN_MENU "That is not a valid bike number."
			else
				# check if input is rented
				RENTAL_ID=$($PSQL "select rental_id from rentals inner join customers using (customer_id) where phone='$PHONE_NUMBER' and bike_id='$BIKE_ID_TO_RETURN' and date_returned is null;")
				# if input not rented
				if [[ -z $RENTAL_ID ]]; then
					# send to main menu
					MAIN_MENU "You do not have that bike rented."
				else
					# update date_returned
					RETURN_BIKE_RESULT=$($PSQL "update rentals set date_returned=now() where rental_id='$RENTAL_ID';")
					# set bike availability to true
					SET_TO_TRUE_RESULT=$($PSQL "update bikes set available=true where bike_id='$BIKE_ID_TO_RETURN';")
					# send to main menu
					MAIN_MENU "Thank you for returning your bike."
				fi
			fi
		fi
	fi
}

EXIT() {
	echo -e "\nThank you for stopping in.\n"
}

MAIN_MENU
