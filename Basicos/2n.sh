#!/bin/bash

#
# Uso básico de un bucle while.
#

contador=1

while [ $contador -le 5 ]; do
    echo "Iteración: $contador"
    ((contador++))
done

exit 0
