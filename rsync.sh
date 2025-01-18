#!/bin/bash

#
# Script para sincronizar archivos al servidor de clase.
#

if [ $# -eq 1 ]; then
    ubicacion=$1
else
    echo "¿Dónde te encuentras? (casa/clase/otro): "
    read -r ubicacion
fi

case "$ubicacion" in
    "clase")
        rsync -avz --progress ./ rodrigobo@10.130.1.200:~/sh
        ;;
    "casa")
        rsync -avz --progress ./ silo@silo.local:~/sh
        ;;
    "otro")
        echo "Introduce el nombre de usuario: "
        read -r usuario
        echo "Introduce la dirección IP: "
        read -r ip
        if [ -z "$usuario" ] || [ -z "$ip" ]; then
            echo "Error: Usuario e IP son obligatorios"
            exit 1
        fi
        rsync -avz --progress ./ "$usuario@$ip:~/sh"
        ;;
    *)
        echo "Error: La ubicación debe ser 'casa', 'clase' u 'otro'"
        exit 1
        ;;
esac

exit 0