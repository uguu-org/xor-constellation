#!/bin/bash
# Same as encode_demo_mp4.sh, but outputs GIF instead of MP4.

set -euo pipefail

palette=$(mktemp --suffix=.png)

ffmpeg \
   -ss 0:00.82 -to 0:36.83 -i captures/playdate-20250525-221708.gif \
   -vf palettegen \
   "$palette"

ffmpeg \
   -ss 0:01.15 -to 0:36.83 -i captures/playdate-20250525-221708.gif \
   -ss 0:00.82 -to 0:01.15 -i captures/playdate-20250525-221708.gif \
   -i "$palette" \
   -filter_complex "[0:v:0][1:v:0]concat=n=2[outv];[outv][2]paletteuse" \
   -y demo.gif

rm -f "$palette"
