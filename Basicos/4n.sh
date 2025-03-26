#!/bin/bash

#
# Uso básico de una condicional if-else.
#

edad=$1

if [ "$edad" -ge 18 ]; then
    echo "Eres mayor de edad"
else
    echo "Eres menor de edad"
fi

exit 0
