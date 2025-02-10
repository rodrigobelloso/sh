#!/bin/bash

#
# Crea una copia de seguridad de /home en una unidad USB.
#

TEMP_DIR="/tmp/home_backup"
BACKUP_FILE="home_listing.txt"
COMPRESSED_FILE="home_listing.tar.gz"

mkdir -p $TEMP_DIR

ls -R $HOME > "$TEMP_DIR/$BACKUP_FILE"

tar -czf "$TEMP_DIR/$COMPRESSED_FILE" -C $TEMP_DIR $BACKUP_FILE

echo "Por favor, inserte la unidad USB y presione ENTER..."
read

USB_MOUNT=$(df -h | grep "/Volumes/" | grep -v "Time Machine" | head -n 1)

if [ -z "$USB_MOUNT" ]; then
    echo "Error: No se detectó ninguna unidad USB"
    exit 1
fi

USB_PATH=$(echo "$USB_MOUNT" | awk '{print $NF}')

if cp "$TEMP_DIR/$COMPRESSED_FILE" "$USB_PATH"; then
    echo "Archivo copiado exitosamente a $USB_PATH"
    echo "El archivo comprimido es: $USB_PATH/$COMPRESSED_FILE"

    rm -rf "$TEMP_DIR"
    
    echo "Para desmontar la unidad USB de forma segura, ejecute:"
    echo "diskutil unmount \"$USB_PATH\""
else
    echo "Error al copiar el archivo"
    exit 1
fi