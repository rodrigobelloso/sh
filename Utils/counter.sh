#!/bin/bash

#
# Script para contar todos los archivos del proyecto
#

cd ..

total_files=$(find . -type f | wc -l)

sh_files=$(find . -name "*.sh" -type f | wc -l)

yml_files=$(find . -name "*.yml" -type f | wc -l)

md_files=$(find . -name "*.md" -type f | wc -l)

echo "Estadísticas del proyecto:"
echo "--------------------------"
echo "Total de archivos: $total_files"
echo "Archivos shell: $sh_files"
echo "Archivos YAML: $yml_files"
echo "Archivos Markdown: $md_files"

exit 0
