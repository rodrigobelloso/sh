#!/bin/bash

#
# Script que simula el lanzamiento de un dado (número aleatorio del 1 al 6).
#

resultado=$(( (RANDOM % 6) + 1 ))

echo "Has lanzado un dado y ha salido: $resultado"

exit 0
