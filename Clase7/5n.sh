#!/bin/bash

#
# Carta aleatoria simple.
#

palos=("Oros" "Copas" "Espadas" "Bastos")
valores=("As" "2" "3" "4" "5" "6" "7" "Sota" "Caballo" "Rey")

palo_aleatorio=$(( RANDOM % 4 ))
valor_aleatorio=$(( RANDOM % 10 ))

echo "Carta: ${valores[$valor_aleatorio]} de ${palos[$palo_aleatorio]}"

exit 0
