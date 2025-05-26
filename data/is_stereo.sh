#!/bin/bash
# Check if a sound sample is stereo by comparing the contents of the
# left and right channels.

if [[ $# -ne 1 ]]; then
   echo "$0 {input.wav}"
   exit 1
fi
INPUT=$1
OUTPUT_LEFT=$(mktemp -p . --suffix=.wav)
OUTPUT_RIGHT=$(mktemp -p . --suffix=.wav)

ffmpeg \
   -i "$INPUT" \
   -map_channel 0.0.0 "$OUTPUT_LEFT" \
   -map_channel 0.0.1 "$OUTPUT_RIGHT" \
   -y

if ( diff -q "$OUTPUT_LEFT" "$OUTPUT_RIGHT" > /dev/null ); then
   echo "$INPUT is mono"
else
   echo "$INPUT is stereo"
fi

rm -f "$OUTPUT_LEFT" "$OUTPUT_RIGHT"
