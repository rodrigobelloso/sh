#!/bin/bash

#
# Script para hacer tablas de multiplicar.
#

if [ $# -ne 1 ]; then
    exit 1
fi

num=$1

for i in {1..10}
do
    result=$((num * i))
    echo "$num x $i = $result"
done

exit 0
