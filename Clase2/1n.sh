#!/bin/bash

#
# Script para imprimir una pirámide de #.
#

read -r -p "Introduce un número: " n

for ((i=1; i<=n; i++))
do
    printf '#%.0s' $(seq 1 "$i")
    printf '\n'
done
