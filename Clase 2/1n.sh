#!/bin/bash

#
# Script para imprimir una pirámide de #.
#

read -p "Introduce un número: " n

for ((i=1; i<=n; i++))
do
    echo "$(printf '#%.0s' $(seq 1 $i))"
done
