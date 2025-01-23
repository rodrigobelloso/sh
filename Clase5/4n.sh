#!/bin/bash

#
# Script que muestra sólo las columnas de login y carpeta de usuario.
#

cut -d: -f1,6 /etc/passwd

exit 0
