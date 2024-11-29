#!/bin/bash

#
# Script para descubrir todas los parámetros de el comando echo.
#

clear

# Usando -e para interpretar caracteres de escape
echo -e "Texto con un alerta:\a" # Muestra una alerta.
echo -e "Texto con un retroceso:\b" # Muestra un retroceso.
echo -e "Texto con una nueva línea:\nNueva línea" # Muestra una nueva línea.
echo -e "Texto con un retorno de carro:\rRetorno de carro" # Muestra un retorno de carro.
echo -e "Texto con una tabulación horizontal:\tTabulación" # Muestra una tabulación horizontal.
echo -e "Texto con una barra invertida:\\" # Muestra una barra invertida.

# Usando -n para no añadir una nueva línea al final
echo -n "Texto sin nueva línea al final"
echo " <- Este texto sigue en la misma línea"
exit 0
