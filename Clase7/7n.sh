#!/bin/bash

#
# Adivinar un número con trampa.
#
# Parámetros disponibles:
#  -v          : Activa el modo verboso (muestra mensajes de depuración)
#  -l          : Activa el registro en un archivo log generado automáticamente
#  -c [1-100]  : Establece un número predefinido (modo trampa)
#
# Ejemplos de uso:
#  ./7n.sh                  : Modo normal, número aleatorio
#  ./7n.sh -v               : Modo verboso, número aleatorio
#  ./7n.sh -l               : Con registro en archivo, número aleatorio
#  ./7n.sh -c 42            : Modo trampa con número 42
#  ./7n.sh -v -l -c 42      : Modo verboso, con registro y número predefinido 42
#

clear

trampa=0
verboso=0
log=0
archivoLog=""

NARANJA='\033[38;5;208m'
RESET='\033[0m'

registrarLog() {
    if [ $log -eq 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$archivoLog"
    fi
}

mostrar() {
    echo "$1"
    registrarLog "$1"
}

depurar() {
    if [ $verboso -eq 1 ]; then
        echo -e "${NARANJA}[DEBUG]:${RESET} $1"
        registrarLog "[DEBUG] $1"
    fi
}

tiempoInicio=$(date +%s)

i=1
while [ $i -le $# ]; do
    param="${!i}"
    
    if [ "$param" = "-v" ]; then
        verboso=1
    elif [ "$param" = "-l" ]; then
        log=1
        archivoLog="$HOME/adivinarElNumero-$(date '+%Y%m%d-%H%M%S').log"
        echo "=== Log de Adivinar el Número - $(date '+%Y-%m-%d %H:%M:%S') ===" > "$archivoLog"
    elif [ "$param" = "-c" ]; then
        ((i++))
        if [ $i -le $# ]; then
            siguiente="${!i}"
            if [[ "$siguiente" =~ ^[0-9]+$ ]] && [ "$siguiente" -ge 1 ] && [ "$siguiente" -le 100 ]; then
                numeroSecreto=$siguiente
                trampa=1
            else
                echo "Error: El número de trampa debe ser un número entre 1 y 100"
                exit 1
            fi
        else
            echo "Error: El parámetro -c requiere un número"
            exit 1
        fi
    fi
    
    ((i++))
done

depurar "Tiempo de inicio: $(date)"
[ $verboso -eq 1 ] && depurar "Modo verboso activado"
[ $log -eq 1 ] && depurar "Registro activado en: $archivoLog"
[ $trampa -eq 1 ] && depurar "Modo trampa activado con número: $numeroSecreto"

if [ -z "$numeroSecreto" ]; then
    numeroSecreto=$((RANDOM % 100 + 1))
    depurar "Generando número aleatorio: $numeroSecreto"
else
    depurar "Usando número predefinido: $numeroSecreto"
fi

mostrar "¡Bienvenido al juego de adivinar el número!"
mostrar "Estoy pensando en un número entre 1 y 100..."

intentos=0
adivinado=0

while [ $adivinado -eq 0 ]; do
    ((intentos++))
    depurar "Iniciando intento número $intentos"
    
    echo -n "Intento $intentos: Introduce un número: "
    read -r respuesta
    
    registrarLog "Intento $intentos: Usuario ha introducido: '$respuesta'"
    depurar "Usuario ha introducido: '$respuesta'"
    
    if ! [[ "$respuesta" =~ ^[0-9]+$ ]]; then
        mostrar "Por favor, introduce un número válido."
        depurar "Entrada no válida, no es un número"
        ((intentos--))
        continue
    fi
    
    if [ "$respuesta" -lt 1 ] || [ "$respuesta" -gt 100 ]; then
        mostrar "El número debe estar entre 1 y 100. Inténtalo de nuevo."
        depurar "Número fuera de rango (1-100)"
        ((intentos--))
        continue
    fi
    
    depurar "Comparando $respuesta con $numeroSecreto"
    
    if [ "$respuesta" -eq "$numeroSecreto" ]; then
        mostrar "¡Felicidades! ¡Has adivinado el número en $intentos intentos!"
        depurar "¡El usuario ha adivinado el número!"
        adivinado=1
    elif [ "$respuesta" -lt "$numeroSecreto" ]; then
        mostrar "El número que buscas es MAYOR que $respuesta."
        depurar "Número introducido demasiado pequeño"
    else
        mostrar "El número que buscas es MENOR que $respuesta."
        depurar "Número introducido demasiado grande"
    fi
done

tiempoFin=$(date +%s)
tiempoTotal=$((tiempoFin - tiempoInicio))

minutos=$((tiempoTotal / 60))
segundos=$((tiempoTotal % 60))

mostrar "Gracias por jugar. ¡Hasta la próxima!"
mostrar "Has tardado $minutos minutos y $segundos segundos en completar el juego."

depurar "Juego finalizado después de $intentos intentos"
depurar "Tiempo total: $tiempoTotal segundos ($minutos minutos y $segundos segundos)"

if [ "$trampa" -eq 1 ]; then
    mostrar "¡OJO! Se han utilizado trampas en esta partida (número predefinido: $numeroSecreto)."
    depurar "Se ha utilizado el modo trampa"
fi

[ $log -eq 1 ] && mostrar "Se ha guardado un registro del juego en: $archivoLog"

exit 0
