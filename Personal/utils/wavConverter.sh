#!/bin/bash

#
# Script to convert M4A audio files to the WAV format.
#

set -e
trap 'echo "❌ error: conversion interrupted."; exit 1' SIGINT SIGTERM

successful_conversions=0
failed_conversions=0
log_file="/tmp/wavConverter_$(date +%Y%m%d_%H%M%S).log"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ error: ffmpeg is not installed. Please install it first."
    exit 1
fi

cd ..

for dir in m4a/Sounds m4a/SoundsMobile; do
    if [ ! -d "$dir" ]; then
        echo "❌ error: directory $dir not found"
        exit 1
    fi
done

mkdir -p wav/Sounds wav/SoundsMobile

convert_file() {
    local input_file="$1"
    local output_dir="$2"
    
    filename=$(basename "$input_file" .m4a)
    echo "🔄 converting: $input_file"
    
    if ffmpeg -i "$input_file" -acodec pcm_s16le -ar 44100 "$output_dir/$filename.wav" -loglevel error 2>> "$log_file"; then
        ((successful_conversions++))
        echo "✅ converted: $filename.wav"
    else
        ((failed_conversions++))
        echo "❌ error converting: $filename.wav"
    fi
}

for file in m4a/Sounds/*.m4a; do
    if [ -f "$file" ]; then
        convert_file "$file" "wav/Sounds"
    fi
done

for file in m4a/SoundsMobile/*.m4a; do
    if [ -f "$file" ]; then
        convert_file "$file" "wav/SoundsMobile"
    fi
done

if [ ! -s "$log_file" ]; then
    rm "$log_file"
fi

echo "
✅ successful: $successful_conversions
❌ failed: $failed_conversions
📝 log: $log_file
"

[ "$failed_conversions" -gt 0 ] && exit 1 || exit 0
