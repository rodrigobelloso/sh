#!/bin/bash

#
# Script para comprobar la cantidad de argumentos y ordenarlos.
#

if [ $# -ne 3 ]; then
    echo "Error: Se requieren exactamente 3 argumentos"
    exit 1
fi

echo "Argumentos ordenados:"
echo "$@" | tr ' ' '\n' | sort
