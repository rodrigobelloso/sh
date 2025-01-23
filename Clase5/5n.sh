#!/bin/bash

#
# Script que crea 10 directorios y un fichero de texto en cada uno.
#

for i in {1..10}
do
    mkdir "dir$i"
    echo "Archivo en el directorio $i" > "dir$i/fichero.txt"
done

exit 0
