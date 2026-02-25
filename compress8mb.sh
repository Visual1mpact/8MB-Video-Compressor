#!/bin/bash
# 8MB Video Compressor for Termux
# Usage: ./compress8mb.sh input.mp4 output.mp4

INPUT="$1"
OUTPUT="$2"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 input.mp4 output.mp4"
    exit 1
fi

# Target size in MB
TARGET_MB=8
TARGET_BITS=$((TARGET_MB * 8192)) # MB -> kilobits

# Get video duration in seconds
DURATION=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
          -of default=noprint_wrappers=1:nokey=1 "$INPUT")
DURATION=${DURATION%.*} # integer seconds

# Get resolution
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width \
        -of csv=p=0 "$INPUT")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height \
         -of csv=p=0 "$INPUT")

# Calculate total target bitrate in kbps
TOTAL_BITRATE=$((TARGET_BITS / DURATION))

# Allocate audio bitrate (kbps)
AUDIO_BITRATE=64
VIDEO_BITRATE=$((TOTAL_BITRATE - AUDIO_BITRATE))

# Optional: downscale if width > 1280 (720p) to save bitrate
if [ "$WIDTH" -gt 1280 ]; then
    SCALE="-vf scale=-2:720"
else
    SCALE=""
fi

echo "Input: $INPUT"
echo "Duration: $DURATION seconds"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Video bitrate: ${VIDEO_BITRATE}k"
echo "Audio bitrate: ${AUDIO_BITRATE}k"

# Single-pass encoding for Termux (fast)
ffmpeg -i "$INPUT" $SCALE -c:v libx264 -b:v "${VIDEO_BITRATE}k" -preset fast \
       -c:a aac -b:a "${AUDIO_BITRATE}k" -movflags +faststart "$OUTPUT"

echo "Compression complete! Output: $OUTPUT (~${TARGET_MB}MB)"