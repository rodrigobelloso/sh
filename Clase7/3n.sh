#!/bin/bash

#
# Bucles recorriendo un array
#

COLORES=("rojo" "verde" "azul" "morado")
NOMBRES=("Pablo" "Juan" "Antonio" "María")

i=0
while [ $i -lt ${#COLORES[@]} ]; do
    echo "Color: ${COLORES[i]}"
    ((i++))
done

echo "-------------------"

j=0
while [ $j -lt ${#NOMBRES[@]} ]; do
    echo "Nombre: ${NOMBRES[j]}"
    ((j++))
done