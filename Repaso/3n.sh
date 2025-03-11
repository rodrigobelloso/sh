#!/bin/bash

#
# Uso básico de un bucle until.
#

numero=1

until [ $numero -gt 5 ]; do
    echo "Valor: $numero"
    ((numero++))
done

exit 0

