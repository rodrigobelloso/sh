#!/bin/bash

#
# Uso básico de la comilla simple.
#

# shellcheck disable=SC2034,SC2016

nombre='María'

echo 'Hola $nombre, hoy es $(date)'

exit 0

# Output: Hola $nombre, hoy es $(date)
