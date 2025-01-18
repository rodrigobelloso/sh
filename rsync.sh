#!/bin/bash

#
# Script para sincronizar archivos al servidor de clase.
#

echo "¿Dónde te encuentras? (casa/clase): "
read ubicacion

if [ "$ubicacion" = "clase" ]; then
    rsync -avz --progress ./ rodrigobo@10.130.1.200:~/sh
elif [ "$ubicacion" = "casa" ]; then
    rsync -avz --progress ./ silo@silo.local:~/sh
else
    echo "Error: Por favor introduce 'casa' o 'clase'"
    exit 1
fi

exit 0
