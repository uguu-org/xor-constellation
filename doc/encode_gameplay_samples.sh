#!/bin/bash

set -euo pipefail

rm -f gameplay_sample{1,2,3}.gif

./reencode_gif.sh ./captures/playdate-20250525-212829.gif gameplay_sample1.gif
./reencode_gif.sh ./captures/playdate-20250525-213027.gif gameplay_sample2.gif
./reencode_gif.sh ./captures/playdate-20250525-213602.gif gameplay_sample3.gif
