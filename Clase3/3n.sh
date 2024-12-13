#!/bin/bash

read -r -p "Introduce un número: " num

for (( i=1; i<=num; i++ ))
do
    for (( j=i; j<num; j++ ))
    do
        echo -n " "
    done
    
    for (( k=1; k<=(2*i-1); k++ ))
    do
        echo -n "*"
    done
    
    echo ""
done
