#!/bin/bash

#
# Script para imprimir un saludo, la fecha y el número de usuarios con sesión iniciada.
#

clear
echo "Hola $USER!"
echo "Espero que estés pasando un buen día.\n"
echo "Hoy es: \c";date
echo "Número de usuarios con la sesión iniciada: \c" ; who | wc -l
echo "Calendario:"
cal
exit 0
