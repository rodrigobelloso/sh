#!/bin/bash

#
# Uso básico de una condicional if-elif-else.
#

nota=75

if [ $nota -ge 90 ]; then
    echo "Sobresaliente"
elif [ $nota -ge 70 ]; then
    echo "Notable"
elif [ $nota -ge 50 ]; then
    echo "Aprobado"
else
    echo "Suspenso"
fi

exit 0
