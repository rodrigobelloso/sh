#!/bin/bash

#
# Script para comprobar si existe una ruta o archivo.
#

echo "Introduce una ruta: "
read -r nombre

if [ -f "$nombre" ]; then
    echo "El archivo existe."
elif [ -d "$nombre" ]; then
    echo "El directorio existe."
else
    echo "No existe ni el archivo ni el directorio."
fi

exit 0
