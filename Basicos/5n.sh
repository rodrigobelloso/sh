#!/bin/bash

#
# Uso básico de una condicional if-elif-else.
#

nota=$1

if [ -z "$nota" ]; then
    echo -n "Introduce la nota (0-100): "
    read -r nota
fi

if [ "$nota" -ge 90 ]; then
    echo "Sobresaliente"
elif [ "$nota" -ge 70 ]; then
    echo "Notable"
elif [ "$nota" -ge 50 ]; then
    echo "Aprobado"
else
    echo "Suspenso"
fi

exit 0
