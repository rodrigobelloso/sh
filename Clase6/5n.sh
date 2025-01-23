#!/bin/bash

#
# Script para visualizar y ordenar archivos.
#

if [ $# -ne 2 ]; then
    echo "Error: Se necesitan exactamente 2 parámetros"
    echo "Uso: $0 fichero opcion(1-4)"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: '$1' no existe o no es un fichero regular"
    exit 1
fi

file="$1"
option="$2"

case $option in
    1)
        cat "$file"
        ;;
    2)
        sort "$file"
        ;;
    3)
        sort -r "$file"
        ;;
    4)
        head -n 4 "$file"
        ;;
    *)
        echo "Error: La opción debe ser un número entre 1 y 4"
        exit 1
        ;;
esac

exit 0
