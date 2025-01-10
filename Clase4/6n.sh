#!/bin/bash

#
# Script que alterna entre mensajes de Hola y Adiós.
#

archivo="control.log"

if [ ! -f "$archivo" ]; then
    echo "Hola"
    echo "1" > "$archivo"
else
    estado=$(cat "$archivo")
    if [ "$estado" = "1" ]; then
        echo "Adios"
        rm "$archivo"
    else
        echo "Hola"
        echo "1" > "$archivo"
    fi
fi

exit 0
