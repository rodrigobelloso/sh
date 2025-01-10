#!/bin/bash

#
# Script para demostrar programación de tareas de usuario
#

cat << 'EOF' > /tmp/crear_usuario.sh
#!/bin/bash
echo "Creando usuario temporal..."
sudo useradd -m tempuser
sudo passwd -d tempuser
echo "Usuario temporal creado: $(date)"
EOF

cat << 'EOF' > /tmp/borrar_usuario.sh
#!/bin/bash
echo "Eliminando usuario temporal..."
sudo userdel -r tempuser
echo "Usuario temporal eliminado: $(date)"
EOF

chmod +x /tmp/crear_usuario.sh
chmod +x /tmp/borrar_usuario.sh

at now + 1 minute << EOF
/tmp/crear_usuario.sh
EOF

at now + 6 minutes << EOF
/tmp/borrar_usuario.sh
EOF

rm /tmp/crear_usuario.sh
rm /tmp/borrar_usuario.sh

exit 0
