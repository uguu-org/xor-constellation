#!/bin/bash
# Convert the colors of the PNGs exported by the simulator to match the
# colors of the GIFs.
#
# GIF uses colors #b4aeac (180,174,172) and #342e2c (52,46,44).
# PNG uses colors #b1afa8 (177,175,168) and #312f28 (49,47,40).

set -euo pipefail

if [[ $# != 2 ]]; then
   echo "$0 {input.png} {output.png}"
   exit 1
fi

input=$1
output=$2

pngtopnm "$input" \
   | ppmtoppm \
   | ppmchange rgb:b1/af/a8 rgb:b4/ae/ac \
   | ppmchange rgb:31/2f/28 rgb:34/2e/2c \
   | pnmtopng -compression 9 > "$output"
