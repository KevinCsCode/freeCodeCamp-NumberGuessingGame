#!/bin/bash
echo -e "Enter your username:"
read USER_NAME
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"
DB_USER=$($PSQL "SELECT name,games_played,best_game FROM users WHERE name = '$USER_NAME'")
if [[ -z $DB_USER ]]
then
	echo -e "Welcome, $USER_NAME! It looks like this is your first time here."
else
	read DB_USER_NAME BAR DB_GAMES_PLAYED BAR DB_BEST_GAME <<< $DB_USER
	echo -e "Welcome back, $USER_NAME! You have played $DB_GAMES_PLAYED games, and your best game took $DB_BEST_GAME guesses."
fi
SECRET_NUMBER=$(($RANDOM % 1000 + 1))
# echo $SECRET_NUMBER
GUESS_NUMBER=-1
NUMBER_OF_GUESSES=0
GUESS_MODULE() {
	NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))
	if [[ -z $1 ]]
	then
		echo -e "Guess the secret number between 1 and 1000:"
	else
		echo -e $1
	fi
	read GUESS_NUMBER
}
NUMBER_CHECK() {
if [[ $GUESS_NUMBER =~ ^[0-9]+$ ]]
then
	DIFF=$(($GUESS_NUMBER-$SECRET_NUMBER))
	if [[ $DIFF -lt 0 ]]
	then
		GUESS_MODULE "It's higher than that, guess again:"
    NUMBER_CHECK
	else
		if [[ $DIFF -gt 0 ]]
		then
			GUESS_MODULE "It's lower than that, guess again:"
      NUMBER_CHECK
			
		fi
	fi
else
	GUESS_MODULE "That is not an integer, guess again:"
  NUMBER_CHECK
fi
}
GUESS_MODULE
NUMBER_CHECK

if [[ -z $DB_USER ]]
then
	NEW_USER_INSERT_RESULT=$($PSQL "INSERT INTO users (name,games_played,best_game) VALUES ('$USER_NAME',1,$NUMBER_OF_GUESSES)")
else
  if [[ -z $DB_BEST_GAME ]]
  then
    DB_BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE name='$USER_NAME'")
  fi
  # echo "Best game previously: $DB_BEST_GAME"
  # echo "Guesses this game: $NUMBER_OF_GUESSES"
  if [[ $DB_BEST_GAME -gt $NUMBER_OF_GUESSES ]]
	then
    # echo "Score improved"
		DB_BEST_GAME=$NUMBER_OF_GUESSES
	fi
	DB_GAMES_PLAYED=$(($DB_GAMES_PLAYED+1))
  if [[ -z $DB_BEST_GAME || -z $DB_GAMES_PLAYED ]]
  then
    echo -e "Issue observed, one of the the variables DB_BEST_GAME, DB_GAMES_PLAYED has an empty value; values are DB_BEST_GAME=$DB_BEST_GAME, DB_GAMES_PLAYED=$DB_GAMES_PLAYED"
    
  else
	  EXISTING_USER_UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$DB_GAMES_PLAYED,best_game=$DB_BEST_GAME WHERE name = '$USER_NAME'")
  fi
fi
echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"