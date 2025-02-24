#!/bin/bash

#
# Script para contar todos los archivos del proyecto.
#

cd ..

total_files=$(find . -not -path '*/\.git/*' -type f | wc -l | tr -d ' ')
sh_files=$(find . -not -path '*/\.git/*' -name "*.sh" -type f | wc -l | tr -d ' ')
yml_files=$(find . -not -path '*/\.git/*' -name "*.yml" -type f | wc -l | tr -d ' ')
md_files=$(find . -not -path '*/\.git/*' -name "*.md" -type f | wc -l | tr -d ' ')

other_files=$((total_files - sh_files - yml_files - md_files))

echo "Estadísticas del proyecto:"
echo "--------------------------"
printf "Total de archivos: %d\n" "$total_files"
printf "Archivos .sh: %d\n" "$sh_files"
printf "Archivos .yml: %d\n" "$yml_files"
printf "Archivos .md: %d\n" "$md_files"
printf "Otros archivos: %d\n" "$other_files"

sum_files=$((sh_files + yml_files + md_files + other_files))

if [ $sum_files -eq $total_files ]; then
    echo "--------------------------"
    echo "La suma de archivos coincide con el total. Todo correcto."
    exit 0
else
    echo "--------------------------"
    printf "Error: La suma de archivos (%d) no coincide con el total (%d).\n" $sum_files "$total_files"
    exit 1
fi
