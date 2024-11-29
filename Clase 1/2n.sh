#!/bin/bash

#
# Script para imprimir un saludo, la fecha y el número de usuarios con sesión iniciada.
#

clear
echo "Hola $USER!" # Mostrará por pantalla el nombre del usuario.
echo "Espero que estés pasando un buen día.\n" # Mostrará por pantalla un mensaje de saludo.
echo "Hoy es: \c";date # Mostrará por pantalla la fecha.
echo "Número de usuarios con la sesión iniciada: \c" ; who | wc -l # Mostrará por pantalla el número de usuarios con la sesión iniciada.
echo "Calendario: ";cal # Mostrará por pantalla el calendario.
exit 0
