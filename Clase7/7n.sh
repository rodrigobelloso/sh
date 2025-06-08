#!/bin/bash

#
# NumberGuessr.sh
# NumberGuessr.sh is a number guessing game where you try to guess a secret number between 1 and 100
#
# Available parameters:
#  -v          : Activates verbose mode (shows debug messages)
#  -l          : Activates logging to an automatically generated log file
#  -c [1-100]  : Sets a predefined number (cheat mode)
#  -r [file]   : Resumes a previously saved game (.ngsave format)
#  -p [key]    : Sets a custom encryption key
#  -h          : Shows help
#
# During the game:
#  Type 'save' at any time to save the current game
#  Type 'quit' at any time to exit the game
#

set -euo pipefail
IFS=$'\n\t'

TEMP_DIR_VALUE="$(mktemp -d)"
if [[ ! -d "$TEMP_DIR_VALUE" ]]; then
    echo "Error: Could not create temporary directory" >&2
    exit 1
fi

readonly TEMP_DIR="$TEMP_DIR_VALUE"
readonly MAX_ATTEMPTS=100
readonly MAX_SAVE_ATTEMPTS=3
readonly ENCRYPTION_ROUNDS=10000

readonly ORANGE='\033[38;5;208m'
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly RESET='\033[0m'

cheatMode=0
verbose=0
logEnabled=0
logFile=""
savedFile=""
loadGame=0
encryptionKey=""
secretNumber=""
attempts=0

trap 'cleanupExit' EXIT INT TERM

cleanupExit() {
    local exitCode=$?
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exitCode
}

showHelp() {
    cat << EOF

NumberGuessr.sh help:
====================

Usage: $0 [OPTIONS]

OPTIONS:
  -v              Activates verbose mode
  -l              Activates file logging
  -c [1-100]      Sets a predefined number (cheat mode)
  -r [file]       Resumes a saved game
  -p [key]        Sets a custom encryption key
  -h              Shows this help

EXAMPLES:
  $0                    # Normal mode
  $0 -v -l              # Verbose mode with logging
  $0 -c 42              # Cheat mode with number 42
  $0 -r game.ngsave     # Resume saved game

During the game, type 'save' to save the current game or 'quit' to exit.
EOF
}

logMessage() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ $logEnabled -eq 1 && -n "$logFile" ]]; then
        printf "[%s] %s\n" "$timestamp" "$message" >> "$logFile" 2>/dev/null || true
    fi
}

display() {
    local message="$1"
    echo -e "$message"
    logMessage "$message"
}

debug() {
    if [[ $verbose -eq 1 ]]; then
        local message="${ORANGE}[DEBUG]:${RESET} $1"
        echo -e "$message" >&2
        logMessage "[DEBUG] $1"
    fi
}

verifyDependencies() {
    local dependencies=("openssl" "tar" "gzip")
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error:${RESET} Missing dependencies: ${missing[*]}" >&2
        echo "Install the required packages and try again." >&2
        exit 1
    fi
}

generateChecksum() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error:${RESET} File not found: $file" >&2
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

validateNumber() {
    local input="$1"
    
    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [[ $input -lt 1 || $input -gt 100 ]]; then
        return 1
    fi
    
    return 0
}

encryptFile() {
    local inputFile="$1"
    local outputFile="$2"
    local key="$3"
    
    debug "Encrypting: $inputFile -> $outputFile"

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
    
    debug "Decrypting: $inputFile -> $outputFile"

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
    
    printf "%s|%s|%s" "$systemInfo" "$userInfo" "$(basename "$0")" | \
        openssl sha256 | awk '{print $NF}'
}

validateSavedFile() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error:${RESET} File not found: $file" >&2
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        echo -e "${RED}Error:${RESET} No read permissions: $file" >&2
        return 1
    fi

    if ! tar -tzf "$file" &>/dev/null; then
        echo -e "${RED}Error:${RESET} Corrupted file or invalid format: $file" >&2
        return 1
    fi
    
    return 0
}

saveGame() {
    local filename="$1"
    local customKey="$2"
    local tempGame="$TEMP_DIR/game.save"
    local tempChecksum="$TEMP_DIR/game.checksum"
    local tempGameEnc="$TEMP_DIR/game_enc.save"
    local tempChecksumEnc="$TEMP_DIR/game_checksum_enc.save"
    
    if [[ -z "$filename" ]]; then
        filename="game-$(date '+%Y%m%d-%H%M%S').ngsave"
    elif [[ ! "$filename" =~ \.ngsave$ ]]; then
        filename="${filename}.ngsave"
    fi
    
    if [[ "$filename" =~ [/\\] ]]; then
        echo -e "${RED}Error:${RESET} Invalid filename" >&2
        return 1
    fi

    cat > "$tempGame" << EOF
secretNumber=$secretNumber
attempts=$attempts
cheatMode=$cheatMode
verbose=$verbose
logEnabled=$logEnabled
logFile=$logFile
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
version=2.0
EOF

    local checksum
    checksum=$(generateChecksum "$tempGame")
    if [[ -z "$checksum" ]]; then
        echo -e "${RED}Error:${RESET} Could not generate checksum" >&2
        return 1
    fi
    
    echo "$checksum" > "$tempChecksum"
    debug "Generated checksum: $checksum"

    local key="${customKey:-${encryptionKey:-$(generateDefaultKey)}}"

    if ! encryptFile "$tempGame" "$tempGameEnc" "$key"; then
        echo -e "${RED}Error:${RESET} Game encryption failed" >&2
        return 1
    fi
    
    if ! encryptFile "$tempChecksum" "$tempChecksumEnc" "$key"; then
        echo -e "${RED}Error:${RESET} Checksum encryption failed" >&2
        return 1
    fi

    local tarFiles=("game_enc.save" "game_checksum_enc.save")

    if [[ $logEnabled -eq 1 && -n "$logFile" && -f "$logFile" ]]; then
        cp "$logFile" "$TEMP_DIR/game_log.log"
        tarFiles+=("game_log.log")
    fi
    
    if tar -czf "$filename" -C "$TEMP_DIR" "${tarFiles[@]}" 2>/dev/null; then
        display "${GREEN}Game saved to:${RESET} $filename"
        return 0
    else
        echo -e "${RED}Error:${RESET} Could not create save file" >&2
        return 1
    fi
}

loadSavedGame() {
    local file="$1"
    local tempDirGame="$TEMP_DIR/load_$$"
    
    if ! validateSavedFile "$file"; then
        return 1
    fi
    
    mkdir -p "$tempDirGame"

    if ! tar -xzf "$file" -C "$tempDirGame" 2>/dev/null; then
        echo -e "${RED}Error:${RESET} Could not extract file" >&2
        return 1
    fi
    
    local gameEnc="$tempDirGame/game_enc.save"
    local checksumEnc="$tempDirGame/game_checksum_enc.save"
    local gameDec="$TEMP_DIR/game_dec.save"
    local checksumDec="$TEMP_DIR/checksum_dec.save"

    if [[ ! -f "$gameEnc" || ! -f "$checksumEnc" ]]; then
        echo -e "${RED}Error:${RESET} Incomplete save file" >&2
        return 1
    fi

    local key="${encryptionKey:-$(generateDefaultKey)}"
    local passwordAttempts=0

    if ! decryptFile "$gameEnc" "$gameDec" "$key"; then
        while [[ $passwordAttempts -lt $MAX_SAVE_ATTEMPTS ]]; do
            ((passwordAttempts++))
            echo -n "Decryption password (attempt $passwordAttempts/$MAX_SAVE_ATTEMPTS): "
            read -rs key
            echo
            
            if decryptFile "$gameEnc" "$gameDec" "$key"; then
                break
            elif [[ $passwordAttempts -lt $MAX_SAVE_ATTEMPTS ]]; then
                echo -e "${RED}Incorrect password${RESET}"
            fi
        done
        
        if [[ $passwordAttempts -eq $MAX_SAVE_ATTEMPTS ]]; then
            echo -e "${RED}Error:${RESET} Maximum attempts reached" >&2
            return 1
        fi
    fi
    
    if ! decryptFile "$checksumEnc" "$checksumDec" "$key"; then
        echo -e "${RED}Error:${RESET} Could not decrypt checksum" >&2
        return 1
    fi
    
    local expectedChecksum actualChecksum
    expectedChecksum=$(cat "$checksumDec" 2>/dev/null)
    actualChecksum=$(generateChecksum "$gameDec")
    
    if [[ "$expectedChecksum" != "$actualChecksum" ]]; then
        echo -e "${RED}Error:${RESET} Corrupted file - checksum mismatch" >&2
        debug "Expected: $expectedChecksum, Actual: $actualChecksum"
        return 1
    fi
    
    display "${GREEN}Integrity verification successful${RESET}"

    while IFS='=' read -r varKey value; do
        case "$varKey" in
            secretNumber) secretNumber="$value" ;;
            attempts) attempts="$value" ;;
            cheatMode) cheatMode="$value" ;;
            verbose) verbose="$value" ;;
            logEnabled) logEnabled="$value" ;;
            logFile) logFile="$value" ;;
        esac
    done < "$gameDec" || { 
        echo -e "${RED}Error:${RESET} Could not load game data" >&2
        return 1
    }

    if [[ $logEnabled -eq 1 && -f "$tempDirGame/game_log.log" ]]; then
        logFile="./continuation_log.log"
        cp "$tempDirGame/game_log.log" "$logFile"
        echo "=== Continuation - $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$logFile"
    fi
    
    display "${GREEN}Game loaded from:${RESET} $file"
    display "Continuing with $attempts attempts made"
    
    return 0
}

processArguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=1
                shift
                ;;
            -l|--log)
                logEnabled=1
                logFile="./log_$(date '+%Y%m%d_%H%M%S').log"
                echo "=== Number Guessing Game Log - $(date '+%Y-%m-%d %H:%M:%S') ===" > "$logFile"
                shift
                ;;
            -p|--password)
                if [[ -n "${2:-}" ]]; then
                    encryptionKey="$2"
                    shift 2
                else
                    echo -e "${RED}Error:${RESET} -p requires a key" >&2
                    exit 1
                fi
                ;;
            -r|--resume)
                if [[ -n "${2:-}" ]]; then
                    savedFile="$2"
                    loadGame=1
                    shift 2
                else
                    echo -e "${RED}Error:${RESET} -r requires a file" >&2
                    exit 1
                fi
                ;;
            -c|--cheat)
                if [[ -n "${2:-}" ]] && validateNumber "$2"; then
                    secretNumber="$2"
                    cheatMode=1
                    shift 2
                else
                    echo -e "${RED}Error:${RESET} -c requires a number between 1-100" >&2
                    exit 1
                fi
                ;;
            -h|--help)
                showHelp
                exit 0
                ;;
            *)
                echo -e "${RED}Error:${RESET} Unknown option: $1" >&2
                echo "Use -h for help" >&2
                exit 1
                ;;
        esac
    done
}

startGame() {
    local startTime endTime totalTime minutes seconds
    startTime=$(date +%s)
    
    debug "Starting game - $(date)"
    
    if [[ $loadGame -eq 1 ]]; then
        if ! loadSavedGame "$savedFile"; then
            exit 1
        fi
    fi

    if [[ -z "$secretNumber" ]]; then
        secretNumber=$((RANDOM % 100 + 1))
        debug "Generated number: $secretNumber"
    fi

    if [[ $loadGame -eq 0 ]]; then
        attempts=0
    fi
    
    display "Welcome to the number guessing game!"
    display "I'm thinking of a number between 1 and 100..."
    
    if [[ $loadGame -eq 1 ]]; then
        display "Continuing game with $attempts attempts made"
    fi

    local guessed=0
    while [[ $guessed -eq 0 && $attempts -lt $MAX_ATTEMPTS ]]; do
        ((attempts++))
        
        echo -n "Attempt $attempts: Number (1-100), 'save', or 'quit': "
        read -r response
        
        logMessage "Attempt $attempts: '$response'"
        debug "User input: '$response'"
        
        if [[ "$response" == "quit" ]]; then
            display "${ORANGE}Game quit by user${RESET}"
            display "The number was: $secretNumber"
            display "You made $((attempts-1)) attempts"
            exit 0
        elif [[ "$response" == "save" ]]; then
            echo -n "Filename (Enter for automatic): "
            read -r saveName
            
            local saveKey="$encryptionKey"
            if [[ -z "$encryptionKey" ]]; then
                echo -n "Set custom password? (y/N): "
                read -r passwordResponse
                if [[ "$passwordResponse" =~ ^[yY]$ ]]; then
                    echo -n "Password: "
                    read -rs saveKey
                    echo
                    echo -n "Confirm: "
                    read -rs confirmPassword
                    echo
                    if [[ "$saveKey" != "$confirmPassword" ]]; then
                        display "${RED}Passwords don't match. Using default key${RESET}"
                        saveKey=""
                    fi
                fi
            fi
            
            if saveGame "$saveName" "$saveKey"; then
                display "To continue: $0 -r [file]"
                if [[ -n "$saveKey" ]]; then
                    display "Remember to use -p for password"
                fi
                exit 0
            fi
            
            ((attempts--))
            continue
        fi
        
        if ! validateNumber "$response"; then
            display "Enter a valid number between 1 and 100, 'save', or 'quit'"
            ((attempts--))
            continue
        fi
        
        if [[ $response -eq $secretNumber ]]; then
            display "${GREEN}Congratulations! You guessed it in $attempts attempts${RESET}"
            guessed=1
        elif [[ $response -lt $secretNumber ]]; then
            display "The number is HIGHER than $response"
        else
            display "The number is LOWER than $response"
        fi
    done
    
    if [[ $guessed -eq 0 ]]; then
        display "${RED}Maximum number of attempts reached!${RESET}"
        display "The number was: $secretNumber"
    fi
    
    endTime=$(date +%s)
    totalTime=$((endTime - startTime))
    minutes=$((totalTime / 60))
    seconds=$((totalTime % 60))
    
    display "Game time: ${minutes}m ${seconds}s"
    
    if [[ $cheatMode -eq 1 ]]; then
        display "${ORANGE}Cheat mode used${RESET}"
    fi
    
    if [[ $logEnabled -eq 1 ]]; then
        display "Log saved to: $logFile"
    fi
    
    debug "Game finished correctly"
}

main() {
    verifyDependencies
    processArguments "$@"
    startGame
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
