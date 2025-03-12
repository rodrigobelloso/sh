#!/bin/bash

#
# Script que recibe argumentos por línea de comando, los guarda en un fichero y los procesa utilizando case para mostrar mensajes personalizados.
#

if [ $# -eq 0 ]; then
    echo "Error: No se han proporcionado argumentos."
    echo "Uso: $0 nombre1 nombre2 nombre3 ..."
    exit 1
fi

TEMP_FILE=$(mktemp)

for arg in "$@"; do
    echo "$arg" >> "$TEMP_FILE"
done

NUM_LINES=$(wc -l < "$TEMP_FILE")
echo "Se han recibido $NUM_LINES argumentos."

for (( i=1; i<=$NUM_LINES; i++ )); do

    NOMBRE=$(head -n $i "$TEMP_FILE" | tail -n 1)
    
    case "$NOMBRE" in
        "Samuel")
            echo "¡Hola Zambue! Arregla ya la bici."
            ;;
        "Izan")
            echo "¡Hola Izan! Pásame el ejercicio 5 de FOL."
            ;;
        "Martin")
            echo "¡Hola Martin! Haz pierna alguna vez."
            ;;
        "Viñas")
            echo "¡Hola Viñas! No comas en clase."
            ;;
        "Manel")
            echo "¡Hola Manel! Deja el League of Legends."
            ;;
        *)
            echo "¡Hola $NOMBRE! No tengo un mensaje personalizado para ti."
            ;;
    esac
done

exit 0
