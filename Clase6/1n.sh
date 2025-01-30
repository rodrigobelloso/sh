#!/bin/bash

#
# Script para calcular el factorial de un número
#

if [ $# -eq 0 ]; then
    echo "Introduce un número: "
    read num
else
    num=$1
fi

if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "Error: Por favor introduce un número entero positivo"
    exit 1
fi

factorial=1

for ((i=1; i<=num; i++)); do
    factorial=$((factorial * i))
done

echo "El factorial de $num es: $factorial"

exit 0
