#!/bin/bash

#
# Script para imprimir una pirámide de #.
#

read -p "Introduce un número: " n # Se pide un número al usuario.

for ((i=1; i<=n; i++)) # Se recorre el rango de 1 a n.
do
    echo "$(printf '#%.0s' $(seq 1 $i))" # Se imprime una cantidad de # igual al valor de i.
done
