#!/bin/bash

#
# Baraja completa sin repeticiones.
#

BARAJA_FILE="$HOME/baraja_espanola.txt"

if [ ! -f "$BARAJA_FILE" ]; then
    : > "$BARAJA_FILE"
    for palo in "Oros" "Copas" "Espadas" "Bastos"; do
        for valor in "As" "2" "3" "4" "5" "6" "7" "Sota" "Caballo" "Rey"; do
            echo "$valor de $palo" >> "$BARAJA_FILE"
        done
    done
    echo "Se ha inicializado una nueva baraja."
fi

cartas_restantes=$(wc -l < "$BARAJA_FILE")

if [ "$cartas_restantes" -eq 0 ]; then
    echo "No quedan cartas en la baraja. Iniciando una nueva."
    : > "$BARAJA_FILE"
    for palo in "Oros" "Copas" "Espadas" "Bastos"; do
        for valor in "As" "2" "3" "4" "5" "6" "7" "Sota" "Caballo" "Rey"; do
            echo "$valor de $palo" >> "$BARAJA_FILE"
        done
    done
    cartas_restantes=40
fi

linea_aleatoria=$(( RANDOM % cartas_restantes + 1 ))

# Obtener la carta antes de eliminarla
carta=$(sed -n "${linea_aleatoria}p" "$BARAJA_FILE")

# Eliminar la carta del archivo
sed -i '' "${linea_aleatoria}d" "$BARAJA_FILE"

echo "Carta: $carta"
echo "Quedan $(( cartas_restantes - 1 )) cartas en la baraja."

exit 0
