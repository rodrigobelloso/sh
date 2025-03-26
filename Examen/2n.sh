#!/bin/bash

echo "Mete un número:"
read altura

printf "%s\n" "$(printf '*%.0s' $(seq 1 $altura))"

for ((i=2; i<=altura; i++)); do
    filaActual=$((altura - i + 1))
    
    espacios=$((altura - filaActual))
    
    printf "%*s%s" $espacios "" "*"
    
    espaciosInternos=$((filaActual - 2))
    
    if [ $i -lt $altura ]; then
        printf "%*s%s\n" $espaciosInternos "" "*"
    else
        printf "\n"
    fi
done

exit 0
