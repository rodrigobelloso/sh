#!/bin/bash

#
# Script para averiguar las operaciones que se pueden hacer.
#

clear
num1=10
num2=5

suma=$((num1 + num2))
echo "Suma: $num1 + $num2 = $suma"

resta=$((num1 - num2))
echo "Resta: $num1 - $num2 = $resta"

multiplicacion=$((num1 * num2))
echo "Multiplicación: $num1 * $num2 = $multiplicacion"

if [ $num2 -ne 0 ]; then
  division=$((num1 / num2))
  echo "División: $num1 / $num2 = $division"
else
  echo "División: No se puede dividir por cero"
fi

modulo=$((num1 % num2))
echo "Módulo: $num1 % $num2 = $modulo"

exponenciacion=$(echo "$num1^$num2" | bc)
echo "Exponenciación: $num1^$num2 = $exponenciacion"

incremento=$((num1 + 1))
echo "Incremento: $num1 incrementado en 1 = $incremento"

decremento=$((num1 - 1))
echo "Decremento: $num1 decrementado en 1 = $decremento"

exit 0
