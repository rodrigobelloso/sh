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

borrarUsuario() {
    echo "Eliminando usuario temporal..."
    sudo userdel -r tempuser
    echo "Usuario temporal eliminado: $(date)"
}

at now + 1 minute << EOF
$(which bash) -c "$(declare -f crearUsuario); crearUsuario"
EOF

at now + 6 minutes << EOF
$(which bash) -c "$(declare -f borrarUsuario); borrarUsuario"
EOF

exit 0
