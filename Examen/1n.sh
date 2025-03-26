#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 numero1 numero2 ..."
    exit 1
fi

anterior=$1
suma=$anterior
numeros=($anterior)
echo "Procesando: $anterior"
shift

while [ $# -gt 0 ]; do
    actual=$1
    echo "Procesando: $actual"
    
    if [ "$actual" -gt "$anterior" ]; then
        anterior=$actual
        suma=$((suma + actual))
        numeros+=($actual)
        shift
    else
        echo "Acabado"
        echo "suma total = $suma" > resultado.txt
        
        for num in "${numeros[@]}"; do
            echo "$num"
        done
        
        echo "+________________"
        echo "$suma"
        exit 0
    fi
done

echo "Terminado"

exit 0
