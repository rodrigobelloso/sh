#!/bin/bash

#
# Script para gestionar los archivos de la papelera.
#

PAPELERA="$HOME/.papelera"

if [ ! -d "$PAPELERA" ]; then
    echo "La papelera está vacía"
    exit 0
fi

NUM_ELEMENTOS=$(find "$PAPELERA" -maxdepth 1 -not -path "$PAPELERA/.info" -not -path "$PAPELERA" | wc -l)

if [ "$NUM_ELEMENTOS" -eq 0 ]; then
    echo "La papelera está vacía"
    exit 0
fi

echo "Contenido de la papelera:"
echo "-------------------------"

for ELEMENTO in "$PAPELERA"/*; do
    if [ "$ELEMENTO" != "$PAPELERA/.info" ]; then
        NOMBRE=$(basename "$ELEMENTO")
        echo -n "- $NOMBRE"
        
        if [ -f "$PAPELERA/.info/$NOMBRE.info" ]; then
            RUTA_ORIGINAL=$(cat "$PAPELERA/.info/$NOMBRE.info")
            echo " (ubicación original: $RUTA_ORIGINAL)"
        else
            echo ""
        fi
    fi
done

ESPACIO=$(du -sh "$PAPELERA" | cut -f1)
echo "-------------------------"
echo "Espacio ocupado: $ESPACIO"

exit 0
