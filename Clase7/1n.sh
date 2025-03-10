#!/bin/bash

#
# Script para borrar archivos y directorios a nuestra papelera.
#

PAPELERA="$HOME/.papelera"

if [ $# -eq 0 ]; then
    echo "Uso: borra <ruta>"
    exit 1
fi

if [ ! -d "$PAPELERA" ]; then
    mkdir -p "$PAPELERA"
    mkdir -p "$PAPELERA/.info"
fi

RUTA_ABSOLUTA=$(realpath "$1")

if [ ! -e "$RUTA_ABSOLUTA" ]; then
    echo "Error: El archivo o directorio '$1' no existe"
    exit 1
fi

NOMBRE=$(basename "$RUTA_ABSOLUTA")

if [ -e "$PAPELERA/$NOMBRE" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    NOMBRE="${NOMBRE}_${TIMESTAMP}"
fi

mv "$RUTA_ABSOLUTA" "$PAPELERA/$NOMBRE"

echo "$RUTA_ABSOLUTA" > "$PAPELERA/.info/$NOMBRE.info"

echo "El elemento '$1' se ha movido a la papelera"

exit 0
