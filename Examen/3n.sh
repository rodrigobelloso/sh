#!/bin/bash

#
# Script que comprueba cada 3 segundos si hay una carpeta de entregas.
#

while true; do
    if [ ! -d "entregas" ]; then
        echo "A la espera de entregas..."
        sleep 3
    else
        echo "Directorio 'entregas' encontrado. Creando carpetas..."
        
        mkdir -p entregas/{1..100}
        
        echo "Se han creado 100 carpetas en el directorio 'entregas'."
        break
    fi
done

exit 0
