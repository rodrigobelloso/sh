#!/bin/bash

#
# Script para buscar un archivo y escribir hola en el.
#

read -r -p "Introduce la ruta del fichero: " archivo

if [ ! -f "$archivo" ]; then
    echo "El archivo no existe o no es un fichero regular"
    exit 1
fi

grep -n "hola" "$archivo" | sed -n '3p' | sed 's/^[0-9]*://'
