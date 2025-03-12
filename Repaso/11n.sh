#!/bin/bash

#
# Uso básico del paso de un parámetro.
#

if [ $# -eq 0 ]; then
    echo "Error: Por favor, proporciona un nombre como parámetro."
    echo "Uso: $0 <nombre>"
    exit 1
fi

nombre=$1

echo "¡Hola, $nombre!"

exit 0
