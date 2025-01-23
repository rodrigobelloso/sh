#!/bin/bash

#
# Script para escribir por pantalla el factorial del mismo.
#

echo "Introduce un número para calcular su factorial:"
read -r num

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