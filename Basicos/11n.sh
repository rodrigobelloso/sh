#!/bin/bash

#
# Uso básico del paso de un parámetro.
#

if [ $# -eq 0 ]; then
    echo "Error: Por favor, proporciona un nombre como parámetro."
    echo "Uso: $0 <nombre> <medida>"
    exit 1
fi

nombre=$1
medida=$2

echo "¡Hola, $nombre! mides $medida metros."

exit 0
