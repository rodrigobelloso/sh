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
        
        for i in {1..100}; do
            mkdir -p "entregas/carpeta $i"
        done
        
        echo "Se han creado 100 carpetas en el directorio 'entregas'."
        break
    fi
done

exit 0
