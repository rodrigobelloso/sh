#!/bin/bash

#
# Script para sincronizar archivos al servidor de clase.
#

if [ $# -eq 1 ]; then
    ubicacion=$1
else
    read -rp "¿Dónde te encuentras? (casa/clase/otro): " ubicacion
fi

case "$ubicacion" in
    "c"|"clase")
        rsync -avz --progress ./ rodrigobo@10.130.1.200:~/sh
        ;;
    "h"|"casa")
        rsync -avz --progress ./ silo@silo.local:~/sh
        ;;
    "o"|"otro")
        read -rp "Introduce el nombre de usuario: " usuario
        read -rp "Introduce la dirección IP: " ip
        if [ -z "$usuario" ] || [ -z "$ip" ]; then
            echo "Error: El usuario y la dirección IP son obligatorios."
            exit 1
        fi
        rsync -avz --progress ./ "$usuario@$ip:~/sh"
        ;;
    *)
        echo "Error: La ubicación debe ser 'c' (clase), 'h' (casa) u 'o' (otro)."
        exit 1
        ;;
esac

exit 0
