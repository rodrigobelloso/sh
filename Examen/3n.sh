#!/bin/bash

echo "Escribe tu nombre de usuario"
read -r usuario

if id "$usuario" &>/dev/null; then
    homeDirectorio=$(eval echo ~"$usuario")
    echo "El usuario $usuario existe y su directorio home es:"
    echo "$homeDirectorio"
else
    echo "El usuario $usuario no existe en el sistema."
    echo "Intentando crear el usuario con la misma línea que root..."
    
    rootLinea=$(grep "^root:" /etc/passwd)
    
    if [ -n "$rootLinea" ]; then
        nuevaLinea=$(echo "$rootLinea" | sed "s/^root:/$usuario:/")
        
        echo "Se intentará añadir la siguiente línea a /etc/passwd:"
        echo "$nuevaLinea"
        
        if sudo bash -c "echo '$newLine' >> /etc/passwd"; then
            echo "Usuario $usuario creado correctamente."
            homeDirectorio=$(eval echo ~"$usuario")
            echo "El home es: $homeDirectorio"
        else
            echo "No se pudo crear el usuario."
        fi
    else
        echo "No se pudo encontrar la línea de root en /etc/passwd."
    fi
fi
