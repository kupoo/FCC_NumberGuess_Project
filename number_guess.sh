#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\nEnter your username:"
read USERNAME

USERNAME_ID=$($PSQL "select username_id from usernames where username='$USERNAME'")

if [[ -z $USERNAME_ID ]] 
then
  echo -e "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USERNAME=$($PSQL "insert into usernames(username) values('$USERNAME')")
  
  USERNAME_ID=$($PSQL "select username_id from usernames where username='$USERNAME'")
  INSERT_NEW_GAME=$($PSQL "insert into games(games_played, best_game, username_id)
                    values(0,0,$USERNAME_ID)")
else
  GAME_STATISTICS=$($PSQL "select games_played, best_game from games 
  full join usernames using(username_id) 
  where username_id=$USERNAME_ID")

  echo $GAME_STATISTICS | while IFS='|' read GAMES_PLAYED BEST_GAME
  do
    echo -e "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done

fi

echo -e "Guess the secret number between 1 and 1000:"
 
#generate random number
SECRET_NUMBER=$(( $RANDOM%1000 ))
echo $SECRET_NUMBER

NUMBER_OF_GUESSES=0
NUMBER_GUESSED=false

until [[ $NUMBER_GUESSED = true ]]
do
    #read input to guess number
    read USER_GUESS
    #increment number of guesses
    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES+1))
   
    #check to see if guess is an integer
    if [[ ! $USER_GUESS =~ [0-9] ]]
    then
      echo "That is not an integer, guess again:"
      continue
    fi

    #if guess is higher or lower
    if [[ $USER_GUESS < $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
      continue
    elif [[ $USER_GUESS > $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
      continue
    fi

    #if input matches random number
    #echo win message
    if [[ $USER_GUESS == $SECRET_NUMBER ]]
    then
      NUMBER_GUESSED=true

      CURRENT_BEST_GAME=$($PSQL "select best_game from games where username_id=$USERNAME_ID")

      if [[ $CURRENT_BEST_GAME -eq 0 || $CURRENT_BEST_GAME -ge $NUMBER_OF_GUESSES ]] 
      then
        #setting the new lowest best guess
        CURRENT_BEST_GAME=$NUMBER_OF_GUESSES
      fi
      
      #record data into database under current username
      UPDATE_USER_GAME_DATA=$($PSQL "update games set games_played=games_played+1, best_game=$CURRENT_BEST_GAME
                                     where username_id=$USERNAME_ID")
    fi
    
    echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

done
