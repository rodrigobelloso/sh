#!/bin/bash

#
# Script para ejecutar el linter de shell localmente
#

# Verificar si shellcheck está instalado
if ! command -v shellcheck &> /dev/null; then
    echo "Error: shellcheck no está instalado"
    echo "Por favor, instálalo con: sudo apt-get install shellcheck"
    exit 1
fi

# Buscar y verificar todos los archivos .sh
echo "Verificando scripts de shell..."
errores=0

while IFS= read -r -d '' archivo; do
    echo "Analizando: $archivo"
    if ! shellcheck "$archivo"; then
        ((errores++))
    fi
done < <(find . -name "*.sh" -type f -print0)

if [ $errores -eq 0 ]; then
    echo "✅ Todos los scripts pasaron la verificación"
    exit 0
else
    echo "❌ Se encontraron $errores scripts con errores"
    exit 1
fi