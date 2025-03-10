#!/bin/bash

#
# Script para mover archivos y directorios de nuestra papelera a su ubicación original.
#

PAPELERA="$HOME/.papelera"

if [ $# -eq 0 ]; then
    echo "Uso: restaura <nombre> [ruta]"
    exit 1
fi

if [ ! -d "$PAPELERA" ]; then
    echo "Error: La papelera no existe"
    exit 1
fi

NOMBRE="$1"

if [ ! -e "$PAPELERA/$NOMBRE" ]; then
    echo "Error: '$NOMBRE' no está en la papelera"
    exit 1
fi

if [ $# -gt 1 ]; then
    DESTINO="$2"
    if [ ! -d "$DESTINO" ]; then
        echo "Error: El directorio destino '$DESTINO' no existe"
        exit 1
    fi
else
    DESTINO="$(pwd)"
fi

if [ -f "$PAPELERA/.info/$NOMBRE.info" ]; then
    RUTA_ORIGINAL=$(cat "$PAPELERA/.info/$NOMBRE.info")
    DIRECTORIO_ORIGINAL=$(dirname "$RUTA_ORIGINAL")
    
    if [ $# -eq 1 ]; then
        if [ -d "$DIRECTORIO_ORIGINAL" ]; then
            DESTINO="$DIRECTORIO_ORIGINAL"
        fi
    fi
fi

if [ -e "$DESTINO/$(basename "$NOMBRE")" ]; then
    echo "Error: Ya existe un archivo con ese nombre en el destino"
    exit 1
fi

mv "$PAPELERA/$NOMBRE" "$DESTINO/"

if [ -f "$PAPELERA/.info/$NOMBRE.info" ]; then
    rm "$PAPELERA/.info/$NOMBRE.info"
fi

echo "El elemento '$NOMBRE' se ha restaurado en '$DESTINO'"

exit 0
