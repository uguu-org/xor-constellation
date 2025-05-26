#!/bin/bash
# Crop the relevant segment from input GIF such that it forms a complete
# loop that starts and ends on a blank screen, and reorder the segments
# so that the first frame of output is the gameplay after the starting
# transition animation.

exec ffmpeg \
   -ss 0:01.15 -to 0:36.83 -i captures/playdate-20250525-221708.gif \
   -ss 0:00.82 -to 0:01.15 -i captures/playdate-20250525-221708.gif \
   -filter_complex "[0:v:0][1:v:0]concat=n=2,scale=w=800:h=480:sws_flags=neighbor[outv]" \
   -map "[outv]" \
   -preset veryslow \
   -y demo.mp4
