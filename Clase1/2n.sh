#!/bin/bash

#
# Script para imprimir un saludo, la fecha y el número de usuarios con sesión iniciada.
#

clear
echo "Hola $USER!"
printf "Espero que estés pasando un buen día.\n\n"
echo "Hoy es: \c";date
echo "Número de usuarios con la sesión iniciada: \c" ; who | wc -l
printf "\nCalendario: "; cal
exit 0
