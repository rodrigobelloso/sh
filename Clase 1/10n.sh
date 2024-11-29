#!/bin/bash

#
# Script para averiguar las operaciones que se pueden hacer.
#

clear
# Definir dos números
num1=10
num2=5

# Suma
suma=$((num1 + num2))
echo "Suma: $num1 + $num2 = $suma"

# Resta
resta=$((num1 - num2))
echo "Resta: $num1 - $num2 = $resta"

# Multiplicación
multiplicacion=$((num1 * num2))
echo "Multiplicación: $num1 * $num2 = $multiplicacion"

# División
if [ $num2 -ne 0 ]; then
  division=$((num1 / num2))
  echo "División: $num1 / $num2 = $division"
else
  echo "División: No se puede dividir por cero"
fi

# Módulo
modulo=$((num1 % num2))
echo "Módulo: $num1 % $num2 = $modulo"

# Exponenciación (no soportada directamente en sh, se puede usar bc)
exponenciacion=$(echo "$num1^$num2" | bc)
echo "Exponenciación: $num1^$num2 = $exponenciacion"

# Incremento
incremento=$((num1 + 1))
echo "Incremento: $num1 incrementado en 1 = $incremento"

# Decremento
decremento=$((num1 - 1))
echo "Decremento: $num1 decrementado en 1 = $decremento"

exit 0
