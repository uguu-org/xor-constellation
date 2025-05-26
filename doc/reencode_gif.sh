#!/bin/bash
# Re-encode a GIF using ffmpeg.  This is needed since the GIFs produced
# by the simulator tend to be very large, and we can usually save a few
# megabytes by re-encoding them.

if [[ $# != 2 ]]; then
   echo "$0 {input.gif} {output.gif}"
   exit 1
fi

set -euo pipefail

input=$1
output=$2
palette=$(mktemp --suffix=.png)

ffmpeg -i "$input" -vf palettegen "$palette"
ffmpeg -i "$input" -i "$palette" -lavfi paletteuse "$output"
rm "$palette"
ls -l "$input"
ls -l "$output"
