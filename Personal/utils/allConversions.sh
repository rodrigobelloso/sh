#!/bin/bash

#
# Script to execute all file converters.
#

clear

echo -e "🎵 starting conversions..."

chmod +x mp3Converter.sh
chmod +x wavConverter.sh
chmod +x oggConverter.sh

echo -e "📀 converting to MP3...\n"
./mp3Converter.sh
mp3_status=$?

echo -e "💿 converting to WAV...\n"
./wavConverter.sh
wav_status=$?

echo -e "📻 converting to OGG...\n"
./oggConverter.sh
ogg_status=$?

if [ $mp3_status -eq 0 ] && [ $wav_status -eq 0 ] && [ $ogg_status -eq 0 ]; then
    echo "🏆 all conversions completed successfully."
    exit 0
else
    echo "👎 some conversions failed."
    exit 1
fi
