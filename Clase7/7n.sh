#!/bin/bash

#
# Adivinar un número con trampa.
#

clear

echo "¡Bienvenido al juego de adivinar el número!"
echo "Estoy pensando en un número entre 1 y 100..."

trampa=0

if [ $# -eq 1 ] && [[ $1 =~ ^[0-9]+$ ]] && [ $1 -ge 1 ] && [ $1 -le 100 ]; then
    numero_secreto=$1
    trampa=1
else
    numero_secreto=$((RANDOM % 100 + 1))
fi

intentos=0
adivinado=0

while [ $adivinado -eq 0 ]; do
    ((intentos++))
    
    echo -n "Intento $intentos: Introduce un número: "
    read respuesta
    
    if ! [[ "$respuesta" =~ ^[0-9]+$ ]]; then
        echo "Por favor, introduce un número válido."
        ((intentos--))
        continue
    fi
    
    if [ $respuesta -eq $numero_secreto ]; then
        echo "¡Felicidades! ¡Has adivinado el número en $intentos intentos!"
        adivinado=1
    elif [ $respuesta -lt $numero_secreto ]; then
        echo "El número que buscas es MAYOR que $respuesta."
    else
        echo "El número que buscas es MENOR que $respuesta."
    fi
done

echo "Gracias por jugar. ¡Hasta la próxima!"

if [ $trampa -eq 1 ]; then
    echo "¡OJO! Se han utilizado trampas en esta partida (número predefinido: $numero_secreto)."
fi

exit 0
