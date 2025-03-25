#!/bin/bash

#
# Parámetro par o impar.
#

if [ $# -eq 0 ]; then
    echo "Error: Debe proporcionar un número como parámetro."
    exit 1
fi

resto=$(( $1 % 2 ))

if [ "$resto" -eq 0 ]; then
    echo "$1 es par."
else
    echo "$1 es impar."
fi

exit 0
