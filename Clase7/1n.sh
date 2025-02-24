#!/bin/bash

#
# Crea una copia de sí mismo usando cat y $0
#

cat '$0' > backup.sh
echo "Se ha creado una copia de seguridad del script en backup.sh"

exit 0
