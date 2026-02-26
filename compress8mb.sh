#!/bin/bash

# ----------------------------------------------------------
# 8MB Guaranteed Video Compressor (Fast, Clean, 2-Pass)
# Uses libx264 with adaptive bitrate retry
# Shows real-time progress bar
# Utilizes all available CPU cores
# ----------------------------------------------------------

# Input / Output arguments
INPUT="$1"
OUTPUT="$2"

# Validate arguments
if [ ! -f "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 input.mp4 output.mp4"
    exit 1
fi

# Target configuration
TARGET_MB=8                 # Desired maximum output size
AUDIO_BITRATE=64            # Fixed audio bitrate (kbps)
THREADS=$(nproc)            # Use all available CPU cores

# Temporary output file for encoding attempts
TMP="${OUTPUT%.*}_tmp.mp4"

# ----------------------------------------------------------
# Extract Media Metadata
# ----------------------------------------------------------

# Get total duration in seconds (strip decimals for integer math)
DURATION=$(ffprobe -v error -show_entries format=duration \
          -of default=noprint_wrappers=1:nokey=1 "$INPUT")
DURATION=${DURATION%.*}

# Calculate total available bitrate budget (in kilobits)
TARGET_BITS=$((TARGET_MB * 8192))

# Allocate video bitrate after reserving audio bitrate
VIDEO_BITRATE=$(( (TARGET_BITS / DURATION) - AUDIO_BITRATE ))

# Detect resolution width to decide if downscaling is needed
WIDTH=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width -of csv=p=0 "$INPUT")
WIDTH=${WIDTH//[^0-9]/}  # Keep only digits

# Downscale to 720p if input width exceeds 1280px
if [ "$WIDTH" -gt 1280 ]; then
    SCALE="-vf scale=-2:720"
else
    SCALE=""
fi

# ----------------------------------------------------------
# Initialization Display
# ----------------------------------------------------------

echo "══════════════════════════════════════"
echo " Duration: ${DURATION}s"
echo " Target: ${TARGET_MB}MB"
echo " Video Bitrate: ${VIDEO_BITRATE}k"
echo " Audio Bitrate: ${AUDIO_BITRATE}k"
echo " Threads: ${THREADS}"
[ -n "$SCALE" ] && echo " Scaling: 720p"
echo " Codec: libx264 (2-pass)"
echo "══════════════════════════════════════"

# ----------------------------------------------------------
# Real-Time Progress Bar
# Parses ffmpeg -progress output
# ----------------------------------------------------------

progress_bar() {
    while read -r line; do
        if [[ $line == out_time_ms=* ]]; then
            ms=${line#*=}
            seconds=$((ms / 1000000))

            # Calculate percentage completion
            percent=$((seconds * 100 / DURATION))
            [ "$percent" -gt 100 ] && percent=100

            # Build 50-character progress bar
            filled=$((percent / 2))
            empty=$((50 - filled))

            printf "\rProgress: ["
            printf "%0.s#" $(seq 1 $filled)
            printf "%0.s " $(seq 1 $empty)
            printf "] %3d%% (%ds/%ds)" \
                   "$percent" "$seconds" "$DURATION"
        fi
    done
}

# ----------------------------------------------------------
# Two-Pass Encoding Function
# ----------------------------------------------------------

encode() {

    # Pass 1:
    # Analyze video complexity (no audio, no output file)
    ffmpeg -y -hide_banner -loglevel error -nostats \
        -i "$INPUT" $SCALE \
        -c:v libx264 -b:v "${VIDEO_BITRATE}k" \
        -preset fast -threads "$THREADS" \
        -pass 1 -an -f mp4 /dev/null

    # Pass 2:
    # Actual encoding using collected statistics
    # Progress data piped into custom progress bar
    ffmpeg -y -hide_banner -loglevel error -nostats \
        -progress pipe:1 \
        -i "$INPUT" $SCALE \
        -c:v libx264 -b:v "${VIDEO_BITRATE}k" \
        -preset fast -threads "$THREADS" \
        -pass 2 \
        -c:a aac -b:a "${AUDIO_BITRATE}k" \
        -movflags +faststart \
        "$TMP" 2>&1 | progress_bar

    echo ""
}

# ----------------------------------------------------------
# Size Enforcement Loop
# If output exceeds 8MB, reduce bitrate by 5% and retry
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

# Cleanup 2-pass log files
rm -f ffmpeg2pass-0.log*

echo "Done: $OUTPUT (~${SIZE}MB)"