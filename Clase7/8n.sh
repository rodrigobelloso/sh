#!/bin/bash

#
# Encriptar o desencriptar un archivo de guardado de juego compatible con 7n.sh
# Ahora soporta archivos .ngsave directamente
#

readonly ENCRYPTION_ROUNDS=10000
readonly MAX_SAVE_ATTEMPTS=3

readonly ORANGE='\033[38;5;208m'
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly RESET='\033[0m'

if [[ $# -lt 2 ]]; then
    echo "Usage:"
    echo "  Para desencriptar: $0 decrypt <ngsave_file> [password]"
    echo "  Para encriptar: $0 encrypt <save_file> <password>"
    echo "  Para re-encriptar: $0 reencrypt <ngsave_file> <old_password> <new_password>"
    echo ""
    echo "Nota: Si no se proporciona contraseña para desencriptar un archivo .ngsave,"
    echo "      se utilizará la clave por defecto del sistema."
    exit 1
fi

ACTION="$1"
SAVE_FILE="$2"
PASSWORD="${3:-}"
TEMP_DIR=$(mktemp -d)

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

validateNgSaveFile() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error:${RESET} Archivo no encontrado: $file" >&2
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        echo -e "${RED}Error:${RESET} Sin permisos de lectura: $file" >&2
        return 1
    fi

    if ! tar -tzf "$file" &>/dev/null; then
        echo -e "${RED}Error:${RESET} Archivo corrupto o formato inválido: $file" >&2
        return 1
    fi
    
    return 0
}

case "$ACTION" in
    "encrypt")
        if [[ $# -ne 3 ]]; then
            echo -e "${RED}Error:${RESET} Para encriptar se necesitan exactamente 3 argumentos"
            echo "Usage: $0 encrypt <save_file> <password>"
            exit 1
        fi
        ;;
    "decrypt")
        if [[ $# -lt 2 ]]; then
            echo -e "${RED}Error:${RESET} Para desencriptar se necesita al menos el archivo"
            echo "Usage: $0 decrypt <ngsave_file> [password]"
            exit 1
        fi
        ;;
    "reencrypt")
        if [[ $# -ne 4 ]]; then
            echo -e "${RED}Error:${RESET} Para re-encriptar se necesitan exactamente 4 argumentos"
            echo "Usage: $0 reencrypt <ngsave_file> <old_password> <new_password>"
            exit 1
        fi
        NEW_PASSWORD="$4"
        ;;
    *)
        echo -e "${RED}Error:${RESET} Acción no válida. Use 'encrypt', 'decrypt' o 'reencrypt'"
        exit 1
        ;;
esac

generateChecksum() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    if command -v sha256sum &> /dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        openssl sha256 "$file" | awk '{print $NF}'
    fi
}

encryptFile() {
    local inputFile="$1"
    local outputFile="$2"
    local key="$3"
    
    if openssl enc -aes-256-gcm -help &>/dev/null; then
        openssl enc -aes-256-gcm -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
                -in "$inputFile" -out "$outputFile" -k "$key" 2>/dev/null
    else
        openssl enc -aes-256-cbc -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
                -in "$inputFile" -out "$outputFile" -k "$key" 2>/dev/null
    fi
}

decryptFile() {
    local inputFile="$1"
    local outputFile="$2"
    local key="$3"
    
    if openssl enc -aes-256-gcm -d -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
            -in "$inputFile" -out "$outputFile" -k "$key" 2>/dev/null; then
        return 0
    elif openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter "$ENCRYPTION_ROUNDS" \
            -in "$inputFile" -out "$outputFile" -k "$key" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

generateDefaultKey() {
    local systemInfo
    systemInfo=$(uname -a 2>/dev/null || echo "unknown")
    local userInfo
    userInfo=$(id -u 2>/dev/null || echo "0")
    
    printf "%s|%s|%s" "$systemInfo" "$userInfo" "7n.sh" | \
        openssl sha256 | awk '{print $NF}'
}

case "$ACTION" in
    "encrypt")
        echo -e "${GREEN}Encriptando archivo...${RESET}"
        
        if [[ ! -f "$SAVE_FILE" ]]; then
            echo -e "${RED}Error:${RESET} El archivo $SAVE_FILE no existe"
            exit 1
        fi
        
        cp "$SAVE_FILE" "$TEMP_DIR/game.save"
        
        checksum=$(generateChecksum "$TEMP_DIR/game.save")
        if [[ -z "$checksum" ]]; then
            echo -e "${RED}Error:${RESET} No se pudo generar checksum"
            exit 1
        fi
        echo "$checksum" > "$TEMP_DIR/game.checksum"
        
        if ! encryptFile "$TEMP_DIR/game.save" "$TEMP_DIR/game_enc.save" "$PASSWORD"; then
            echo -e "${RED}Error:${RESET} Falló la encriptación del archivo principal"
            exit 1
        fi
            
        if ! encryptFile "$TEMP_DIR/game.checksum" "$TEMP_DIR/game_checksum_enc.save" "$PASSWORD"; then
            echo -e "${RED}Error:${RESET} Falló la encriptación del checksum"
            exit 1
        fi
        
        OUTPUT_FILE="${SAVE_FILE%.*}_encrypted.ngsave"
        if tar -czf "$OUTPUT_FILE" -C "$TEMP_DIR" game_enc.save game_checksum_enc.save 2>/dev/null; then
            echo -e "${GREEN}Archivo encriptado guardado como:${RESET} $OUTPUT_FILE"
        else
            echo -e "${RED}Error:${RESET} No se pudo crear el archivo .ngsave"
            exit 1
        fi
        ;;
        
    "decrypt")
        echo -e "${GREEN}Desencriptando archivo .ngsave...${RESET}"
        
        if ! validateNgSaveFile "$SAVE_FILE"; then
            exit 1
        fi
        
        echo "Extrayendo contenido del archivo..."
        if ! tar -xzf "$SAVE_FILE" -C "$TEMP_DIR" 2>/dev/null; then
            echo -e "${RED}Error:${RESET} No se pudo extraer el archivo"
            exit 1
        fi
        
        echo "Archivos encontrados en el .ngsave:"
        ls -la "$TEMP_DIR"
        
        key=""
        if [[ -n "$PASSWORD" ]]; then
            key="$PASSWORD"
            echo "Usando contraseña proporcionada..."
        else
            key=$(generateDefaultKey)
            echo "Usando clave por defecto del sistema..."
        fi
        
        gameEnc="$TEMP_DIR/game_enc.save"
        checksumEnc="$TEMP_DIR/game_checksum_enc.save"
        gameDec="$TEMP_DIR/game.save"
        checksumDec="$TEMP_DIR/game.checksum"
        
        if [[ ! -f "$gameEnc" ]]; then
            echo -e "${RED}Error:${RESET} No se encontró game_enc.save en el archivo .ngsave"
            exit 1
        fi
        
        echo "Desencriptando archivo principal..."
        passwordAttempts=0
        decryptSuccess=0
        
        if decryptFile "$gameEnc" "$gameDec" "$key"; then
            echo -e "${GREEN}✓ Archivo principal desencriptado exitosamente${RESET}"
            decryptSuccess=1
        else

            if [[ -z "$PASSWORD" ]]; then
                echo -e "${ORANGE}La clave por defecto no funcionó. Se requiere contraseña personalizada.${RESET}"
                while [[ $passwordAttempts -lt $MAX_SAVE_ATTEMPTS ]]; do
                    ((passwordAttempts++))
                    echo -n "Contraseña de desencriptación (intento $passwordAttempts/$MAX_SAVE_ATTEMPTS): "
                    read -rs key
                    echo
                    
                    if decryptFile "$gameEnc" "$gameDec" "$key"; then
                        echo -e "${GREEN}✓ Archivo desencriptado exitosamente${RESET}"
                        decryptSuccess=1
                        break
                    elif [[ $passwordAttempts -lt $MAX_SAVE_ATTEMPTS ]]; then
                        echo -e "${RED}Contraseña incorrecta${RESET}"
                    fi
                done
            else
                echo -e "${RED}Error:${RESET} Contraseña incorrecta o archivo corrupto"
            fi
        fi
        
        if [[ $decryptSuccess -eq 0 ]]; then
            echo -e "${RED}Error:${RESET} No se pudo desencriptar el archivo"
            exit 1
        fi
        
        if [[ -f "$checksumEnc" ]]; then
            echo "Desencriptando checksum..."
            if decryptFile "$checksumEnc" "$checksumDec" "$key"; then
                echo -e "${GREEN}✓ Checksum desencriptado exitosamente${RESET}"
                
                echo "Verificando integridad del archivo..."
                expectedChecksum=$(cat "$checksumDec" 2>/dev/null)
                actualChecksum=$(generateChecksum "$gameDec")
                
                if [[ "$expectedChecksum" == "$actualChecksum" ]]; then
                    echo -e "${GREEN}✓ Verificación de integridad exitosa${RESET}"
                else
                    echo -e "${ORANGE}⚠ Advertencia: Checksum no coincide - archivo podría estar corrupto${RESET}"
                    echo "  Esperado: $expectedChecksum"
                    echo "  Actual: $actualChecksum"
                fi
            else
                echo -e "${ORANGE}Advertencia: No se pudo desencriptar el checksum${RESET}"
            fi
        else
            echo -e "${ORANGE}Advertencia: No se encontró archivo de checksum${RESET}"
        fi

        if [[ -f "$gameDec" && -s "$gameDec" ]]; then
            echo ""
            echo -e "${GREEN}Contenido del archivo de guardado:${RESET}"
            echo "=================================="
            cat "$gameDec"
            echo "=================================="
            echo ""

            OUTPUT_FILE="${SAVE_FILE%.*}_decrypted.save"
            cp "$gameDec" "$OUTPUT_FILE"
            
            echo -e "${GREEN}Archivo desencriptado guardado como:${RESET} $OUTPUT_FILE"
            echo "Tamaño del archivo: $(wc -c < "$OUTPUT_FILE") bytes"

            if [[ -f "$TEMP_DIR/game_log.log" ]]; then
                LOG_OUTPUT="${SAVE_FILE%.*}_log.log"
                cp "$TEMP_DIR/game_log.log" "$LOG_OUTPUT"
                echo -e "${GREEN}Log del juego extraído como:${RESET} $LOG_OUTPUT"
            fi
        else
            echo -e "${RED}Error:${RESET} El archivo desencriptado está vacío o no existe"
            exit 1
        fi
        ;;
        
    "reencrypt")
        echo -e "${GREEN}Re-encriptando archivo .ngsave...${RESET}"

        if ! validateNgSaveFile "$SAVE_FILE"; then
            exit 1
        fi

        if ! tar -xzf "$SAVE_FILE" -C "$TEMP_DIR" 2>/dev/null; then
            echo -e "${RED}Error:${RESET} No se pudo extraer el archivo"
            exit 1
        fi
        
        gameEnc="$TEMP_DIR/game_enc.save"
        checksumEnc="$TEMP_DIR/game_checksum_enc.save"
        gameDec="$TEMP_DIR/game.save"
        checksumDec="$TEMP_DIR/game.checksum"

        echo "Desencriptando con contraseña antigua..."
        if ! decryptFile "$gameEnc" "$gameDec" "$PASSWORD"; then
            echo -e "${RED}Error:${RESET} Contraseña anterior incorrecta o archivo corrupto"
            exit 1
        fi
        
        if [[ -f "$checksumEnc" ]]; then
            if ! decryptFile "$checksumEnc" "$checksumDec" "$PASSWORD"; then
                echo -e "${ORANGE}Advertencia: No se pudo desencriptar el checksum${RESET}"
            fi
        fi

        echo "Re-encriptando con nueva contraseña..."
        if ! encryptFile "$gameDec" "$gameEnc" "$NEW_PASSWORD"; then
            echo -e "${RED}Error:${RESET} Falló la re-encriptación del archivo principal"
            exit 1
        fi
        
        if [[ -f "$checksumDec" ]]; then
            if ! encryptFile "$checksumDec" "$checksumEnc" "$NEW_PASSWORD"; then
                echo -e "${RED}Error:${RESET} Falló la re-encriptación del checksum"
                exit 1
            fi
        fi

        OUTPUT_FILE="${SAVE_FILE%.*}_reencrypted.ngsave"
        tarFiles=("game_enc.save")
        
        if [[ -f "$checksumEnc" ]]; then
            tarFiles+=("game_checksum_enc.save")
        fi
        
        if [[ -f "$TEMP_DIR/game_log.log" ]]; then
            tarFiles+=("game_log.log")
        fi
        
        if tar -czf "$OUTPUT_FILE" -C "$TEMP_DIR" "${tarFiles[@]}" 2>/dev/null; then
            echo -e "${GREEN}Archivo re-encriptado guardado como:${RESET} $OUTPUT_FILE"
        else
            echo -e "${RED}Error:${RESET} No se pudo crear el archivo re-encriptado"
            exit 1
        fi
        ;;
esac

echo -e "${GREEN}Operación completada exitosamente${RESET}"