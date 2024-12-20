#!/bin/bash

#
# Restaura la tabla de particiones desde cualquier ubicación.
#

restaurarTablaParticiones() {
    clear
    sudo bash -c 'cat /mnt/share/bckp/partTable/pi/sf | sfdisk /dev/mmcblk0 --no-reread'
    clear
    reboot
    exit 0
}

while true; do
    printf "Estás a punto de restaurar la tabla de particiones mientras el sistema está en ejecución. \a\n"
    read -r -p "¿Estás seguro de esto? [s,n]: " respuesta
    
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
            printf "\n"
            ;;
    esac
done