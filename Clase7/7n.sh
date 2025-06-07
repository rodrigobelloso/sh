#!/bin/bash

#
# Adivinar un número.
#
# Parámetros disponibles:
#  -v          : Activa el modo verboso (muestra mensajes de depuración)
#  -l          : Activa el registro en un archivo log generado automáticamente
#  -c [1-100]  : Establece un número predefinido (modo trampa)
#  -r [archivo]: Retoma una partida guardada anteriormente
#  -p [clave]  : Establece una clave de encriptación personalizada
#  -h          : Muestra ayuda
#
# Durante el juego:
#  Escribe 'guardar' en cualquier momento para guardar la partida actual
#

set -euo pipefail
IFS=$'\n\t'

readonly TEMP_DIR
TEMP_DIR="$(mktemp -d)"
readonly MAX_ATTEMPTS=100
readonly MAX_SAVE_ATTEMPTS=3
readonly ENCRYPTION_ROUNDS=10000

readonly NARANJA='\033[38;5;208m'
readonly ROJO='\033[1;31m'
readonly VERDE='\033[1;32m'
readonly RESET='\033[0m'

trampa=0
verboso=0
log_habilitado=0
archivo_log=""
archivo_guardado=""
cargar_partida=0
clave_encriptacion=""
numero_secreto=""
intentos=0

trap 'cleanup_exit' EXIT INT TERM

cleanup_exit() {
    local exit_code=$?
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exit_code
}

mostrar_ayuda() {
    cat << EOF
Uso: $0 [OPCIONES]

OPCIONES:
  -v              Activa el modo verboso
  -l              Activa el registro en archivo log
  -c [1-100]      Establece un número predefinido (modo trampa)
  -r [archivo]    Retoma una partida guardada
  -p [clave]      Establece una clave de encriptación personalizada
  -h              Muestra esta ayuda

EJEMPLOS:
  $0                    # Modo normal
  $0 -v -l              # Modo verboso con log
  $0 -c 42              # Modo trampa con número 42
  $0 -r partida.save    # Retomar partida guardada

Durante el juego, escribe 'guardar' para guardar la partida actual.
EOF
}

log_mensaje() {
    local mensaje="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ $log_habilitado -eq 1 && -n "$archivo_log" ]]; then
        printf "[%s] %s\n" "$timestamp" "$mensaje" >> "$archivo_log" 2>/dev/null || true
    fi
}

mostrar() {
    local mensaje="$1"
    echo -e "$mensaje"
    log_mensaje "$mensaje"
}

depurar() {
    if [[ $verboso -eq 1 ]]; then
        local mensaje="${NARANJA}[DEBUG]:${RESET} $1"
        echo -e "$mensaje" >&2
        log_mensaje "[DEBUG] $1"
    fi
}

verificar_dependencias() {
    local dependencias=("openssl" "tar" "gzip")
    local faltantes=()
    
    for dep in "${dependencias[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            faltantes+=("$dep")
        fi
    done
    
    if [[ ${#faltantes[@]} -gt 0 ]]; then
        echo -e "${ROJO}Error:${RESET} Dependencias faltantes: ${faltantes[*]}" >&2
        echo "Instala los paquetes requeridos e intenta de nuevo." >&2
        exit 1
    fi
}

generar_checksum() {
    local archivo="$1"
    
    if [[ ! -f "$archivo" ]]; then
        echo -e "${ROJO}Error:${RESET} Archivo no encontrado: $archivo" >&2
        return 1
    fi
    
    if command -v sha256sum &> /dev/null; then
        sha256sum "$archivo" | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$archivo" | cut -d' ' -f1
    else
        openssl sha256 "$archivo" | awk '{print $NF}'
    fi
}

validar_numero() {
    local input="$1"
    
    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [[ $input -lt 1 || $input -gt 100 ]]; then
        return 1
    fi
    
    return 0
}

encriptar_archivo() {
    local archivo_entrada="$1"
    local archivo_salida="$2"
    local clave="$3"
    
    depurar "Encriptando: $archivo_entrada -> $archivo_salida"

    if openssl enc -aes-256-gcm -help &>/dev/null; then
        openssl enc -aes-256-gcm -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
                -in "$archivo_entrada" -out "$archivo_salida" -k "$clave" 2>/dev/null
    else
        openssl enc -aes-256-cbc -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
                -in "$archivo_entrada" -out "$archivo_salida" -k "$clave" 2>/dev/null
    fi
}

desencriptar_archivo() {
    local archivo_entrada="$1"
    local archivo_salida="$2"
    local clave="$3"
    
    depurar "Desencriptando: $archivo_entrada -> $archivo_salida"

    if openssl enc -aes-256-gcm -d -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
            -in "$archivo_entrada" -out "$archivo_salida" -k "$clave" 2>/dev/null; then
        return 0
    elif openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
            -in "$archivo_entrada" -out "$archivo_salida" -k "$clave" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

generar_clave_default() {
    local sistema_info
    sistema_info=$(uname -a 2>/dev/null || echo "unknown")
    local user_info
    user_info=$(id -u 2>/dev/null || echo "0")
    
    printf "%s|%s|%s" "$sistema_info" "$user_info" "$(basename "$0")" | \
        openssl sha256 | awk '{print $NF}'
}

validar_archivo_guardado() {
    local archivo="$1"

    if [[ ! -f "$archivo" ]]; then
        echo -e "${ROJO}Error:${RESET} Archivo no encontrado: $archivo" >&2
        return 1
    fi

    if [[ ! -r "$archivo" ]]; then
        echo -e "${ROJO}Error:${RESET} Sin permisos de lectura: $archivo" >&2
        return 1
    fi

    if ! tar -tzf "$archivo" &>/dev/null; then
        echo -e "${ROJO}Error:${RESET} Archivo corrupto o formato inválido: $archivo" >&2
        return 1
    fi
    
    return 0
}

guardar_partida() {
    local nombre_archivo="$1"
    local clave_personalizada="$2"
    local temp_partida="$TEMP_DIR/partida.save"
    local temp_checksum="$TEMP_DIR/partida.checksum"
    local temp_partida_enc="$TEMP_DIR/partida_enc.save"
    local temp_checksum_enc="$TEMP_DIR/partida_checksum_enc.save"
    
    if [[ -z "$nombre_archivo" ]]; then
        nombre_archivo="partida-$(date '+%Y%m%d-%H%M%S').tar.gz"
    elif [[ ! "$nombre_archivo" =~ \.tar\.gz$ ]]; then
        nombre_archivo="${nombre_archivo}.tar.gz"
    fi
    
    if [[ "$nombre_archivo" =~ [/\\] ]]; then
        echo -e "${ROJO}Error:${RESET} Nombre de archivo inválido" >&2
        return 1
    fi

    cat > "$temp_partida" << EOF
numero_secreto=$numero_secreto
intentos=$intentos
trampa=$trampa
verboso=$verboso
log_habilitado=$log_habilitado
archivo_log=$archivo_log
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
version=2.0
EOF

    local checksum
    checksum=$(generar_checksum "$temp_partida")
    if [[ -z "$checksum" ]]; then
        echo -e "${ROJO}Error:${RESET} No se pudo generar checksum" >&2
        return 1
    fi
    
    echo "$checksum" > "$temp_checksum"
    depurar "Checksum generado: $checksum"

    local clave="${clave_personalizada:-${clave_encriptacion:-$(generar_clave_default)}}"

    if ! encriptar_archivo "$temp_partida" "$temp_partida_enc" "$clave"; then
        echo -e "${ROJO}Error:${RESET} Fallo en encriptación de partida" >&2
        return 1
    fi
    
    if ! encriptar_archivo "$temp_checksum" "$temp_checksum_enc" "$clave"; then
        echo -e "${ROJO}Error:${RESET} Fallo en encriptación de checksum" >&2
        return 1
    fi

    local archivos_tar=("partida_enc.save" "partida_checksum_enc.save")

    if [[ $log_habilitado -eq 1 && -n "$archivo_log" && -f "$archivo_log" ]]; then
        cp "$archivo_log" "$TEMP_DIR/partida_log.log"
        archivos_tar+=("partida_log.log")
    fi
    
    if tar -czf "$nombre_archivo" -C "$TEMP_DIR" "${archivos_tar[@]}" 2>/dev/null; then
        mostrar "${VERDE}Partida guardada en:${RESET} $nombre_archivo"
        return 0
    else
        echo -e "${ROJO}Error:${RESET} No se pudo crear el archivo de guardado" >&2
        return 1
    fi
}

cargar_partida_guardada() {
    local archivo="$1"
    local temp_dir_partida="$TEMP_DIR/load_$$"
    
    if ! validar_archivo_guardado "$archivo"; then
        return 1
    fi
    
    mkdir -p "$temp_dir_partida"

    if ! tar -xzf "$archivo" -C "$temp_dir_partida" 2>/dev/null; then
        echo -e "${ROJO}Error:${RESET} No se pudo extraer el archivo" >&2
        return 1
    fi
    
    local partida_enc="$temp_dir_partida/partida_enc.save"
    local checksum_enc="$temp_dir_partida/partida_checksum_enc.save"
    local partida_dec="$TEMP_DIR/partida_dec.save"
    local checksum_dec="$TEMP_DIR/checksum_dec.save"

    if [[ ! -f "$partida_enc" || ! -f "$checksum_enc" ]]; then
        echo -e "${ROJO}Error:${RESET} Archivo de guardado incompleto" >&2
        return 1
    fi

    local clave="${clave_encriptacion:-$(generar_clave_default)}"
    local intentos_password=0

    if ! desencriptar_archivo "$partida_enc" "$partida_dec" "$clave"; then
        while [[ $intentos_password -lt $MAX_SAVE_ATTEMPTS ]]; do
            ((intentos_password++))
            echo -n "Contraseña de desencriptación (intento $intentos_password/$MAX_SAVE_ATTEMPTS): "
            read -rs clave
            echo
            
            if desencriptar_archivo "$partida_enc" "$partida_dec" "$clave"; then
                break
            elif [[ $intentos_password -lt $MAX_SAVE_ATTEMPTS ]]; then
                echo -e "${ROJO}Contraseña incorrecta${RESET}"
            fi
        done
        
        if [[ $intentos_password -eq $MAX_SAVE_ATTEMPTS ]]; then
            echo -e "${ROJO}Error:${RESET} Máximo de intentos alcanzado" >&2
            return 1
        fi
    fi
    
    if ! desencriptar_archivo "$checksum_enc" "$checksum_dec" "$clave"; then
        echo -e "${ROJO}Error:${RESET} No se pudo desencriptar checksum" >&2
        return 1
    fi
    
    local checksum_esperado checksum_actual
    checksum_esperado=$(cat "$checksum_dec" 2>/dev/null)
    checksum_actual=$(generar_checksum "$partida_dec")
    
    if [[ "$checksum_esperado" != "$checksum_actual" ]]; then
        echo -e "${ROJO}Error:${RESET} Archivo corrupto - checksum no coincide" >&2
        depurar "Esperado: $checksum_esperado, Actual: $checksum_actual"
        return 1
    fi
    
    mostrar "${VERDE}Verificación de integridad exitosa${RESET}"

    while IFS='=' read -r clave valor; do
        case "$clave" in
            numero_secreto) numero_secreto="$valor" ;;
            intentos) intentos="$valor" ;;
            trampa) trampa="$valor" ;;
            verboso) verboso="$valor" ;;
            log_habilitado) log_habilitado="$valor" ;;
            archivo_log) archivo_log="$valor" ;;
        esac
    done < "$partida_dec" || { 
        echo -e "${ROJO}Error:${RESET} No se pudieron cargar los datos de partida" >&2
        return 1
    }

    if [[ $log_habilitado -eq 1 && -f "$temp_dir_partida/partida_log.log" ]]; then
        archivo_log="./log_continuacion.log"
        cp "$temp_dir_partida/partida_log.log" "$archivo_log"
        echo "=== Continuación - $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$archivo_log"
    fi
    
    mostrar "${VERDE}Partida cargada desde:${RESET} $archivo"
    mostrar "Continuando con $intentos intentos realizados"
    
    return 0
}

procesar_argumentos() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verboso=1
                shift
                ;;
            -l|--log)
                log_habilitado=1
                archivo_log="./log_$(date '+%Y%m%d_%H%M%S').log"
                echo "=== Log Adivinar Número - $(date '+%Y-%m-%d %H:%M:%S') ===" > "$archivo_log"
                shift
                ;;
            -p|--password)
                if [[ -n "${2:-}" ]]; then
                    clave_encriptacion="$2"
                    shift 2
                else
                    echo -e "${ROJO}Error:${RESET} -p requiere una clave" >&2
                    exit 1
                fi
                ;;
            -r|--resume)
                if [[ -n "${2:-}" ]]; then
                    archivo_guardado="$2"
                    cargar_partida=1
                    shift 2
                else
                    echo -e "${ROJO}Error:${RESET} -r requiere un archivo" >&2
                    exit 1
                fi
                ;;
            -c|--cheat)
                if [[ -n "${2:-}" ]] && validar_numero "$2"; then
                    numero_secreto="$2"
                    trampa=1
                    shift 2
                else
                    echo -e "${ROJO}Error:${RESET} -c requiere un número entre 1-100" >&2
                    exit 1
                fi
                ;;
            -h|--help)
                mostrar_ayuda
                exit 0
                ;;
            *)
                echo -e "${ROJO}Error:${RESET} Opción desconocida: $1" >&2
                echo "Usa -h para ver la ayuda" >&2
                exit 1
                ;;
        esac
    done
}

iniciar_juego() {
    local tiempo_inicio tiempo_fin tiempo_total minutos segundos
    tiempo_inicio=$(date +%s)
    
    depurar "Iniciando juego - $(date)"
    
    if [[ $cargar_partida -eq 1 ]]; then
        if ! cargar_partida_guardada "$archivo_guardado"; then
            exit 1
        fi
    fi

    if [[ -z "$numero_secreto" ]]; then
        numero_secreto=$((RANDOM % 100 + 1))
        depurar "Número generado: $numero_secreto"
    fi

    if [[ $cargar_partida -eq 0 ]]; then
        intentos=0
    fi
    
    mostrar "¡Bienvenido al juego de adivinar el número!"
    mostrar "Estoy pensando en un número entre 1 y 100..."
    
    if [[ $cargar_partida -eq 1 ]]; then
        mostrar "Continuando partida con $intentos intentos realizados"
    fi

    local adivinado=0
    while [[ $adivinado -eq 0 && $intentos -lt $MAX_ATTEMPTS ]]; do
        ((intentos++))
        
        echo -n "Intento $intentos: Número (1-100) o 'guardar': "
        read -r respuesta
        
        log_mensaje "Intento $intentos: '$respuesta'"
        depurar "Entrada del usuario: '$respuesta'"
        
        if [[ "$respuesta" == "guardar" ]]; then
            echo -n "Nombre del archivo (Enter para automático): "
            read -r nombre_guardado
            
            local clave_guardado="$clave_encriptacion"
            if [[ -z "$clave_encriptacion" ]]; then
                echo -n "¿Establecer contraseña personalizada? (s/N): "
                read -r respuesta_password
                if [[ "$respuesta_password" =~ ^[sS]$ ]]; then
                    echo -n "Contraseña: "
                    read -rs clave_guardado
                    echo
                    echo -n "Confirmar: "
                    read -rs confirm_password
                    echo
                    if [[ "$clave_guardado" != "$confirm_password" ]]; then
                        mostrar "${ROJO}Contraseñas no coinciden. Usando clave por defecto${RESET}"
                        clave_guardado=""
                    fi
                fi
            fi
            
            if guardar_partida "$nombre_guardado" "$clave_guardado"; then
                mostrar "Para continuar: $0 -r [archivo]"
                if [[ -n "$clave_guardado" ]]; then
                    mostrar "Recuerda usar -p para la contraseña"
                fi
                exit 0
            fi
            
            ((intentos--))
            continue
        fi
        
        if ! validar_numero "$respuesta"; then
            mostrar "Introduce un número válido entre 1 y 100"
            ((intentos--))
            continue
        fi
        
        if [[ $respuesta -eq $numero_secreto ]]; then
            mostrar "${VERDE}¡Felicidades! Adivinaste en $intentos intentos${RESET}"
            adivinado=1
        elif [[ $respuesta -lt $numero_secreto ]]; then
            mostrar "El número es MAYOR que $respuesta"
        else
            mostrar "El número es MENOR que $respuesta"
        fi
    done
    
    if [[ $adivinado -eq 0 ]]; then
        mostrar "${ROJO}¡Máximo de intentos alcanzado!${RESET}"
        mostrar "El número era: $numero_secreto"
    fi
    
    tiempo_fin=$(date +%s)
    tiempo_total=$((tiempo_fin - tiempo_inicio))
    minutos=$((tiempo_total / 60))
    segundos=$((tiempo_total % 60))
    
    mostrar "Tiempo de juego: ${minutos}m ${segundos}s"
    
    if [[ $trampa -eq 1 ]]; then
        mostrar "${NARANJA}Modo trampa utilizado${RESET}"
    fi
    
    if [[ $log_habilitado -eq 1 ]]; then
        mostrar "Log guardado en: $archivo_log"
    fi
    
    depurar "Juego finalizado correctamente"
}

main() {
    verificar_dependencias
    procesar_argumentos "$@"
    iniciar_juego
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi