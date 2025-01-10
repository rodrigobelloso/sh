#!/bin/bash

#
# Script para demostrar programación de tareas de usuario
#

crearUsuario() {
    echo "Creando usuario temporal..."
    sudo useradd -m tempuser
    sudo passwd -d tempuser
    echo "Usuario temporal creado: $(date)"
}
export -f crearUsuario

borrarUsuario() {
    echo "Eliminando usuario temporal..."
    sudo userdel -r tempuser
    echo "Usuario temporal eliminado: $(date)"
}
export -f borrarUsuario

echo "crearUsuario" | at now + 1 minute

echo "borrarUsuario" | at now + 6 minutes

exit 0
