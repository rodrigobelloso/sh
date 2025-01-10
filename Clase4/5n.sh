#!/bin/bash

#
# Script que muestra el número de usuarios conectados.
#

usuarios=$(who | wc -l)

echo "Actualmente hay $usuarios usuarios conectados"

if [ $usuarios -gt 2 ]; then
    echo "3 son multitud"
fi
exit 0;
