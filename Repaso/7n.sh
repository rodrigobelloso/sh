#!/bin/bash

#
# Uso básico de un operador ternario.
#

edad=20

mensaje=$( [ $edad -ge 18 ] && echo "Mayor de edad" || echo "Menor de edad" )
echo "$mensaje"

exit 0
