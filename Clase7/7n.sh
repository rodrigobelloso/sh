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
#  -m [1-200]  : Sets maximum number of attempts (default: 50)
#  -h          : Shows help
#
# During the game:
#  Type 'save' at any time to save the current game
#  Type 'quit' at any time to exit the game
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
TEMP_DIR="$(mktemp -d -t numberguessr.XXXXXX)"
readonly TEMP_DIR
readonly DEFAULT_MAX_ATTEMPTS=50
readonly MAX_SAVE_ATTEMPTS=3
readonly ENCRYPTION_ROUNDS=10000
readonly SAVE_FORMAT_VERSION="2.1"

readonly NUMBERGUESSR_DIR="$HOME/.numberguessr"
readonly SAVES_DIR="$NUMBERGUESSR_DIR/saves"
readonly LOGS_DIR="$NUMBERGUESSR_DIR/logs"
readonly CONFIG_DIR="$NUMBERGUESSR_DIR/config"
readonly CONFIG_FILE="$CONFIG_DIR/.ngconf"

readonly ORANGE='\033[38;5;208m'
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly YELLOW='\033[1;33m'
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
maxAttempts=$DEFAULT_MAX_ATTEMPTS

trap 'cleanupExit' EXIT INT TERM

cleanupExit() {
    local exitCode=$?
    if [[ -d "$TEMP_DIR" ]]; then
        find "$TEMP_DIR" -type f -exec rm -f {} \; 2>/dev/null || true
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    exit $exitCode
}

createNumberGuessrDirectories() {
    debug "Checking NumberGuessr directory structure..."
    
    local dirs=("$NUMBERGUESSR_DIR" "$SAVES_DIR" "$LOGS_DIR" "$CONFIG_DIR")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if ! mkdir -p "$dir" 2>/dev/null; then
                echo -e "${RED}Error:${RESET} Could not create directory: $dir" >&2
                exit 1
            fi
            chmod 700 "$dir"
            debug "Created directory: $dir"
        else
            debug "Directory exists: $dir"
        fi
    done
    
    debug "NumberGuessr directory structure verified successfully"
}

createDefaultConfig() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'EOF'
defaultMaxAttempts=50
autoLog=false
verboseMode=false
saveDirectory=auto
logDirectory=auto
EOF
        chmod 600 "$CONFIG_FILE"
        debug "Created default configuration file: $CONFIG_FILE"
    else
        debug "Configuration file already exists: $CONFIG_FILE"
    fi
}

loadConfig() {
    if [[ -f "$CONFIG_FILE" ]]; then
        debug "Loading configuration from: $CONFIG_FILE"
        
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            
            case "$key" in
                defaultMaxAttempts)
                    if validateMaxAttempts "$value"; then
                        maxAttempts="$value"
                        debug "Config: Set max attempts to $value"
                    fi
                    ;;
                autoLog)
                    if [[ "$value" == "true" ]]; then
                        logEnabled=1
                        logFile="$LOGS_DIR/log_$(date '+%Y%m%d_%H%M%S').log"
                        echo "=== Number Guessing Game Log - $(date '+%Y-%m-%d %H:%M:%S') ===" > "$logFile"
                        chmod 600 "$logFile"
                        debug "Config: Auto-logging enabled"
                    fi
                    ;;
                verboseMode)
                    if [[ "$value" == "true" ]]; then
                        verbose=1
                        debug "Config: Verbose mode enabled"
                    fi
                    ;;
            esac
        done < "$CONFIG_FILE"
    else
        debug "No configuration file found"
    fi
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
  -m [1-200]      Sets maximum number of attempts (default: 50)
  -h              Shows this help

EXAMPLES:
  $0                    # Normal mode
  $0 -v -l              # Verbose mode with logging
  $0 -c 42              # Cheat mode with number 42
  $0 -m 30              # Set maximum attempts to 30
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
    logMessage "$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')"
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
    
    [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 && $input -le 100 ]]
}

validateMaxAttempts() {
    local input="$1"
    
    [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 && $input -le 200 ]]
}

validateFilename() {
    local filename="$1"
    
    if [[ "$filename" =~ [^a-zA-Z0-9._-] ]]; then
        return 1
    fi
    
    if [[ ${#filename} -gt 255 ]]; then
        return 1
    fi
    
    if [[ "$filename" =~ ^\.\./ || "$filename" =~ /\.\./ || "$filename" =~ /\.\.$  ]]; then
        return 1
    fi
    
    return 0
}

secureRandom() {
    if [[ -c /dev/urandom ]]; then
        od -vAn -N4 -tu4 < /dev/urandom | tr -d ' '
    else
        echo $((RANDOM * RANDOM))
    fi
}

encryptFile() {
    local inputFile="$1"
    local outputFile="$2"
    local key="$3"
    
    debug "Encrypting: $(basename "$inputFile") -> $(basename "$outputFile")"

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
    
    debug "Decrypting: $(basename "$inputFile") -> $(basename "$outputFile")"

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
    local systemInfo userInfo
    systemInfo=$(uname -a 2>/dev/null || echo "unknown")
    userInfo=$(id -u 2>/dev/null || echo "0")
    
    printf "%s|%s|%s|%s" "$systemInfo" "$userInfo" "$(basename "$0")" "$(stat -c %i "$SCRIPT_DIR" 2>/dev/null || echo "0")" | \
        openssl sha256 2>/dev/null | awk '{print $NF}' || echo "fallback$(date +%s)"
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

    local fileSize
    fileSize=$(stat -c%s "$file" 2>/dev/null || wc -c < "$file" 2>/dev/null)
    if [[ -z "$fileSize" || $fileSize -gt 10485760 ]]; then
        echo -e "${RED}Error:${RESET} File too large or invalid: $file" >&2
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

    local baseFilename
    baseFilename=$(basename "$filename")
    if ! validateFilename "$baseFilename"; then
        echo -e "${RED}Error:${RESET} Invalid filename" >&2
        return 1
    fi

    if [[ ! "$filename" =~ / ]]; then
        filename="$SAVES_DIR/$filename"
    fi

    cat > "$tempGame" << EOF
secretNumber=$secretNumber
attempts=$attempts
maxAttempts=$maxAttempts
cheatMode=$cheatMode
verbose=$verbose
logEnabled=$logEnabled
logFile=$logFile
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
version=$SAVE_FORMAT_VERSION
scriptHash=$(sha256sum "$0" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
EOF

    chmod 600 "$tempGame"

    local checksum
    checksum=$(generateChecksum "$tempGame")
    if [[ -z "$checksum" ]]; then
        echo -e "${RED}Error:${RESET} Could not generate checksum" >&2
        return 1
    fi
    
    echo "$checksum" > "$tempChecksum"
    chmod 600 "$tempChecksum"
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
        chmod 600 "$TEMP_DIR/game_log.log"
        tarFiles+=("game_log.log")
    fi
    
    if tar -czf "$filename" -C "$TEMP_DIR" "${tarFiles[@]}" 2>/dev/null; then
        chmod 600 "$filename"
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
    chmod 700 "$tempDirGame"

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

    local loadedVersion=""
    while IFS='=' read -r varKey value; do
        case "$varKey" in
            secretNumber) 
                if validateNumber "$value"; then
                    secretNumber="$value"
                else
                    echo -e "${RED}Error:${RESET} Invalid secret number in save file" >&2
                    return 1
                fi
                ;;
            attempts) 
                if [[ "$value" =~ ^[0-9]+$ ]] && [[ $value -ge 0 ]]; then
                    attempts="$value"
                else
                    echo -e "${RED}Error:${RESET} Invalid attempts count in save file" >&2
                    return 1
                fi
                ;;
            maxAttempts) 
                if validateMaxAttempts "$value"; then
                    maxAttempts="$value"
                else
                    echo -e "${YELLOW}Warning:${RESET} Invalid max attempts in save file, using current value"
                fi
                ;;
            cheatMode) [[ "$value" =~ ^[01]$ ]] && cheatMode="$value" ;;
            verbose) [[ "$value" =~ ^[01]$ ]] && verbose="$value" ;;
            logEnabled) [[ "$value" =~ ^[01]$ ]] && logEnabled="$value" ;;
            logFile) logFile="$value" ;;
            version) loadedVersion="$value" ;;
        esac
    done < "$gameDec" || { 
        echo -e "${RED}Error:${RESET} Could not load game data" >&2
        return 1
    }

    if [[ -n "$loadedVersion" && "$loadedVersion" != "$SAVE_FORMAT_VERSION" ]]; then
        display "${YELLOW}Warning:${RESET} Save file format version mismatch (loaded: $loadedVersion, current: $SAVE_FORMAT_VERSION)"
    fi

    if [[ $logEnabled -eq 1 && -f "$tempDirGame/game_log.log" ]]; then
        logFile="$LOGS_DIR/continuation_log_$(date '+%Y%m%d_%H%M%S').log"
        cp "$tempDirGame/game_log.log" "$logFile"
        chmod 600 "$logFile"
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
                logFile="$LOGS_DIR/log_$(date '+%Y%m%d_%H%M%S').log"
                echo "=== Number Guessing Game Log - $(date '+%Y-%m-%d %H:%M:%S') ===" > "$logFile"
                chmod 600 "$logFile"
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
                    if [[ ! "$2" =~ / ]]; then
                        savedFile="$SAVES_DIR/$2"
                    else
                        savedFile="$2"
                    fi
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
            -m|--max-attempts)
                if [[ -n "${2:-}" ]] && validateMaxAttempts "$2"; then
                    maxAttempts="$2"
                    shift 2
                else
                    echo -e "${RED}Error:${RESET} -m requires a number between 1-200" >&2
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
        local randomValue
        randomValue=$(secureRandom)
        secretNumber=$((randomValue % 100 + 1))
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
    local lastGuess=""
    
    while [[ $guessed -eq 0 && $attempts -lt $maxAttempts ]]; do
        ((attempts++))
        
        echo -n "Attempt $attempts of $maxAttempts: Number (1-100), 'save', or 'quit': "
        read -r response
        
        logMessage "Attempt $attempts: '$response'"
        debug "User input: '$response'"
        
        case "$response" in
            quit|q)
                display "${ORANGE}Game quit by user${RESET}"
                display "The number was: $secretNumber"
                display "You made $((attempts-1)) attempts"
                exit 0
                ;;
            save|s)
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
                ;;
            *)
                if ! validateNumber "$response"; then
                    display "Enter a valid number between 1 and 100, 'save', or 'quit'"
                    ((attempts--))
                    continue
                fi
                
                if [[ "$response" == "$lastGuess" ]]; then
                    display "${YELLOW}You already guessed $response. Try a different number.${RESET}"
                    ((attempts--))
                    continue
                fi
                
                lastGuess="$response"
                
                if [[ $response -eq $secretNumber ]]; then
                    display "${GREEN}Congratulations! You guessed it in $attempts attempts${RESET}"
                    guessed=1
                elif [[ $response -lt $secretNumber ]]; then
                    display "The number is HIGHER than $response"
                else
                    display "The number is LOWER than $response"
                fi
                ;;
        esac
    done
    
    if [[ $guessed -eq 0 ]]; then
        display "${RED}Maximum number of attempts reached!${RESET}"
        display "The number was: $secretNumber"
    fi
    
    endTime=$(date +%s)
    totalTime=$((endTime - startTime))
    minutes=$((totalTime / 60))
    seconds=$((totalTime % 60))
    
    if [[ $minutes -gt 0 ]]; then
        display "Game time: ${minutes}m ${seconds}s"
    else
        display "Game time: ${seconds}s"
    fi
    
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
    createNumberGuessrDirectories
    createDefaultConfig
    loadConfig
    processArguments "$@"
    startGame
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
