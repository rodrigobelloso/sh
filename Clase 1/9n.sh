#!/bin/bash

#
# Script para descubrir todas los parámetros de el comando echo.
#

clear

echo -e "Texto con un alerta:\a"
echo -e "Texto con un retroceso:\b"
echo -e "Texto con una nueva línea:\nNueva línea"
echo -e "Texto con un retorno de carro:\rRetorno de carro"
echo -e "Texto con una tabulación horizontal:\tTabulación"
echo -e "Texto con una barra invertida:\\"

echo -n "Texto sin nueva línea al final"
echo " <- Este texto sigue en la misma línea"
exit 0
