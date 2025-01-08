#!/bin/bash

#
# Script para imprimir una pirámide de # alineada hacia la derecha.
#

clear

while true; do
    read -r -p "Introduce un número: " n
    if [[ "$n" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Por favor, introduce un número válido"
    fi
done

for ((i=1; i<=n; i++))
do
    printf '%*s\n' "$n" "$(printf '#%.0s' $(seq 1 "$i"))"
done

exit 0

