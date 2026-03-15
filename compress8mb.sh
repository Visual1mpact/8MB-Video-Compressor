#!/bin/bash

# ----------------------------------------------------------
# 8MB Guaranteed Video Compressor (Fast, Clean, 2-Pass)
# ----------------------------------------------------------

DEFAULT_TARGET_MB=8

# Ask user for target size
read -p "Enter target size in MB (default $DEFAULT_TARGET_MB MB): " INPUT_MB
TARGET_MB=${INPUT_MB:-$DEFAULT_TARGET_MB}

# Ask user if they want to mute audio
read -p "Remove audio? (y/N): " REMOVE_AUDIO
if [[ "$REMOVE_AUDIO" =~ ^[Yy]$ ]]; then
    MUTE=true
    AUDIO_BITRATE=0
else
    MUTE=false
    AUDIO_BITRATE=64
fi

echo "Target output size: ${TARGET_MB}MB"
echo "Audio muted: $MUTE"

# Input / Output arguments
INPUT="$1"
OUTPUT="$2"

if [ ! -f "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 input.mp4 output.mp4"
    exit 1
fi

THREADS=$(nproc)
TMP="${OUTPUT%.*}_tmp.mp4"

# ----------------------------------------------------------
# Extract metadata
# ----------------------------------------------------------
DURATION=$(ffprobe -v error -show_entries format=duration \
          -of default=noprint_wrappers=1:nokey=1 "$INPUT")
DURATION=${DURATION%.*}

# Calculate total bitrate budget in kbps
TOTAL_BITS=$((TARGET_MB * 8192))  # 1 MB = 8192 kilobits

# Allocate video bitrate
# If muted, full budget goes to video
VIDEO_BITRATE=$(( TOTAL_BITS / DURATION - AUDIO_BITRATE ))

WIDTH=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width -of csv=p=0 "$INPUT")
WIDTH=${WIDTH//[^0-9]/}
SCALE=$([ "$WIDTH" -gt 1280 ] && echo "-vf scale=-2:720" || echo "")

# ----------------------------------------------------------
# Display info
# ----------------------------------------------------------
echo "══════════════════════════════════════"
echo " Duration: ${DURATION}s"
echo " Target: ${TARGET_MB}MB"
echo " Video Bitrate: ${VIDEO_BITRATE}k"
[ "$MUTE" = false ] && echo " Audio Bitrate: ${AUDIO_BITRATE}k" || echo " Audio: muted"
echo " Threads: ${THREADS}"
[ -n "$SCALE" ] && echo " Scaling: 720p"
echo " Codec: libx264 (2-pass)"
echo "══════════════════════════════════════"

# ----------------------------------------------------------
# Progress bar
# ----------------------------------------------------------
progress_bar() {
    while read -r line; do
        if [[ $line == out_time_ms=* ]]; then
            ms=${line#*=}
            seconds=$((ms / 1000000))
            percent=$((seconds * 100 / DURATION))
            [ "$percent" -gt 100 ] && percent=100
            filled=$((percent / 2))
            empty=$((50 - filled))
            printf "\rProgress: ["
            printf "%0.s#" $(seq 1 $filled)
            printf "%0.s " $(seq 1 $empty)
            printf "] %3d%% (%ds/%ds)" "$percent" "$seconds" "$DURATION"
        fi
    done
}

# ----------------------------------------------------------
# Two-pass encoding
# ----------------------------------------------------------
encode() {
    # Pass 1: analyze video only
    ffmpeg -y -hide_banner -loglevel error -nostats \
        -i "$INPUT" $SCALE \
        -c:v libx264 -b:v "${VIDEO_BITRATE}k" \
        -preset fast -threads "$THREADS" \
        -pass 1 -an -f mp4 /dev/null

    # Pass 2: actual encoding
    if [ "$MUTE" = true ]; then
        AUDIO_FLAGS="-an"
    else
        AUDIO_FLAGS="-c:a aac -b:a ${AUDIO_BITRATE}k"
    fi

    ffmpeg -y -hide_banner -loglevel error -nostats \
        -progress pipe:1 \
        -i "$INPUT" $SCALE \
        -c:v libx264 -b:v "${VIDEO_BITRATE}k" \
        -preset fast -threads "$THREADS" \
        -pass 2 \
        $AUDIO_FLAGS \
        -movflags +faststart \
        "$TMP" 2>&1 | progress_bar
    echo ""
}

# ----------------------------------------------------------
# Size enforcement
# ----------------------------------------------------------
while true; do
    encode
    SIZE=$(du -m "$TMP" | cut -f1)
    if [ "$SIZE" -le "$TARGET_MB" ]; then
        mv "$TMP" "$OUTPUT"
        break
    else
        # Reduce video bitrate by 5% and retry
        VIDEO_BITRATE=$((VIDEO_BITRATE * 95 / 100))
    fi
done

rm -f ffmpeg2pass-0.log*
echo "Done: $OUTPUT (~${SIZE}MB)"