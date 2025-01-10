#!/bin/bash

#
# Script para buscar un proceso y matarlo.
#

if [ $# -ne 1 ]; then
    echo "Uso: $0 <process_name>"
    exit 1
fi

busqueda="$1"

pids=$(pgrep -f "$busqueda" | grep -v $$)

if [ -z "$pids" ]; then
    echo "No se ha encontrado el proceso: $busqueda"
    exit 0
fi

for pid in $pids; do
    echo "Se ha matado el proceso $pid"
    kill -9 $pid 2>/dev/null
done

echo "Se han matado todos los procesos que coinciden con: $busqueda"
exit 0
