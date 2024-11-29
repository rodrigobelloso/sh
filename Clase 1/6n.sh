#!/bin/bash

#
# Script para hacer una pequeña suma de números predefinidos.
#

clear
n1=10 # Se asigna el valor 10 a la variable n1.
n2=30 # Se asigna el valor 30 a la variable n2.
echo "Se van a sumar $n1 y $n2" # Se muestra por pantalla los valores de las variables n1 y n2.
resultado=$((n1 + n2)) # Se realiza la suma de las variables n1 y n2 y se asigna el resultado a la variable resultado.
echo "El resultado es: $resultado" # Se muestra por pantalla el resultado de la suma.
exit 0
