#!/bin/bash

#
# Solicita el nombre al usuario y muestra un mensaje de bienvenida
#

echo "Por favor, ingresa tu nombre:"
read -r nombre

if [ -z "$nombre" ]; then
    echo "Error: El nombre no puede estar vacío"
    exit 1
fi

echo "¡Hola $nombre, bienvenido al mundo de la programación en bash!"
exit 0
