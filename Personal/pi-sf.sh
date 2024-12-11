#!/bin/bash

#
# Restaura la tabla de particiones desde cualquier ubicación.
#

restaurarTablaParticiones() {
    clear
    sudo sfdisk /dev/mmcblk0 < /mnt/share/bckp/partTable/pi/sf --no-reread
    clear
    reboot
    exit 0
}

while true; do
    echo "Estás a punto de restaurar la tabla de particiones mientras el sistema está en ejecución. \a"
    read -p "¿Estás seguro de esto? [s,n]: " respuesta
    
    case $respuesta in
        s|S)
            restaurarTablaParticiones
            ;;
        n|N)
            clear
            exit 0
            ;;
        *)
            echo "$respuesta es una opción inválida, por favor escribe 's' o 'n'."
            echo "\n"
            ;;
    esac
done
