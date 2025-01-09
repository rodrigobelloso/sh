#!/bin/bash

#
# Script para sincronizar archivos al servidor remoto
#

REMOTE_USER="rodrigobo"
REMOTE_HOST="10.130.1.200"
REMOTE_PATH="~/sh"
SOURCE_DIR="./"

if ! command -v rsync &> /dev/null; then
    echo "Error: rsync no está instalado"
    exit 1
fi

rsync -avzh --progress --stats \
    "${SOURCE_DIR}" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}" || {
    echo "Error: falló la sincronización"
    exit 1
}

echo "Sincronización completada exitosamente"
