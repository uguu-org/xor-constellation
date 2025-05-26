#!/bin/bash
# Wrapper for launching Inkscape.
#
# This wrapper does three things:
#
# 1. Keep all the paths and flags in one place.
#
#    We could have just embedded these inside the Makefile, but it's cleaner
#    to keep them here.
#
# 2. Cache output.
#
#    For every input SVG, cache the output PNG using the hash of the SVG
#    contents as the key.  If we see the same hash again, we can just copy
#    the PNG output from earlier, without having to run Inkscape again.
#
#    We do this because most of our images are generated from a single
#    master SVG that is split into multiple layers.  Changes to any single
#    layer will not affect the rasterized output the other layers, but the
#    timestamps of other layers will be updated because the master SVG has
#    changed.  The cache helps to avoid launching Inkscape for the unchanged
#    layers.
#
# 3. Serialize invocations of Inkscape.
#
#    This script runs Inkscape with `flock` such that we don't have multiple
#    instances of Inkscape starting at the same time (which we would get
#    with "make -j" if this script didn't block it).  Inkscape starting in
#    parallel often result in errors like this:
#
#      terminate called after throwing an instance of 'Gio::DBus::Error'
#
#    By the way, Inkscape running in parallel (as opposed to starting)
#    appears to work fine, keeping an interactive session of Inkscape open
#    while running `make` have not caused any trouble.  Or perhaps it works
#    because Inkscape was idle while `make` is running, who knows.  Your
#    safest bet is to always close all instances of Inkscape before running
#    this script.

if [[ $# -ne 2 && $# -ne 6 && $# -ne 7 ]]; then
   echo "$0 {input.svg} {output.png} [x1] [y1] [x2] [y2] [dpi]"
   exit 1
fi
INPUT=$1
OUTPUT=$2

set -euo pipefail

# Path to Inkscape.  This is the Windows version of Inkscape and not the
# version that is distributed with Cygwin, even though all other scripts
# here expect Cygwin.
#
# We need at least version 1.4 to enable "--export-png-antialias" flag.
# https://gitlab.com/inkscape/inkscape/-/merge_requests/5167
#
# The same merge request above also added "--export-png-compression".
# The default is 6, which appears to encode at the same speed as 0 (and
# significantly faster than 9), so we kept the default.
INKSCAPE="c:/Program Files/Inkscape/bin/inkscape.exe"

# Use cached output if available.  This works by hashing the contents of the
# input SVG and finding an existing file named with that hash.
#
# Only the file contents are hashed, and not any of the resources that might
# be referenced.  We could check all xlink:href attributes and see if they
# reference any external files, but since we only use so few of those, we
# will just manually invalidate all caches whenever we change those files.
INPUT_HASH=$(md5sum "$INPUT" | awk '{print $1}')
PREFIX=$(dirname "$0")/t_svg_cache
CACHED_OUTPUT="${PREFIX}_${INPUT_HASH}.png"
EXPORT_DPI="--export-dpi=96"
if [[ $# -eq 6 ]]; then
   X1=$3
   Y1=$4
   X2=$5
   Y2=$6
   AREA="--export-area=$X1:$Y1:$X2:$Y2"
   FULL_PAGE_CACHE="$CACHED_OUTPUT"
   CACHED_OUTPUT="${PREFIX}_${INPUT_HASH}_${X1}_${Y1}_${X2}_${Y2}.png"
else
   if [[ $# -eq 7 ]]; then
      X1=$3
      Y1=$4
      X2=$5
      Y2=$6
      EXPORT_DPI="--export-dpi=$7"
      AREA="--export-area=$X1:$Y1:$X2:$Y2"
      FULL_PAGE_CACHE="$CACHED_OUTPUT"
      CACHED_OUTPUT="${PREFIX}_${INPUT_HASH}_${X1}_${Y1}_${X2}_${Y2}_${7}.png"
   else
      AREA="--export-area-page"
   fi
fi

if [[ -s "$CACHED_OUTPUT" ]]; then
   # Do not overwrite output file if it's identical to cached contents.
   # This allows make to skip rebuilding downstream dependants.
   #
   # A side effect of this is that make may invoke this script repeatedly
   # because the output timestamp has not been updated (as intended).
   # This generates a bit of visual noise every time we run make, but the
   # few seconds saved in incremental updates is worth the noise.
   if ( diff -q -N "$CACHED_OUTPUT" "$OUTPUT" > /dev/null ); then
      exit 0
   fi
   exec cp "$CACHED_OUTPUT" "$OUTPUT"
fi

# If we wanted to rasterize an area and we already have the full page
# rasterized, we will generate the area image by cropping from the
# full image.  This is faster than invoking Inkscape, especially since
# it doesn't not require flock.
if [[ $# -eq 6 && -s "$FULL_PAGE_CACHE" ]]; then
   WIDTH=$(($X2 - $X1))
   HEIGHT=$(($Y2 - $Y1))
   convert \
      "$FULL_PAGE_CACHE" \
      -crop "${WIDTH}x${HEIGHT}+${X1}+${Y1}" \
      "$CACHED_OUTPUT"
   if ( diff -q -N "$CACHED_OUTPUT" "$OUTPUT" > /dev/null ); then
      exit 0
   fi
   exec cp "$CACHED_OUTPUT" "$OUTPUT"
fi

flock $(dirname "$0")/t_inkscape.lock "$INKSCAPE" \
   "$AREA" \
   "$EXPORT_DPI" \
   --export-type=png \
   --export-png-color-mode=RGBA_8 \
   --export-png-antialias=0 \
   --export-background=black \
   --export-background-opacity=0 \
   --export-filename="$CACHED_OUTPUT" \
   "$INPUT"

# We ran Inkscape because we didn't have a cache entry for this output image,
# but it's still possible that the new output is identical to what already
# exists.  This happens when we make an edit that doesn't affect the pixels
# in the image (e.g. renaming a path or group), so we apply the diff check
# before replacing output file to avoid rebuilding downstream dependants.
if ( diff -q -N "$CACHED_OUTPUT" "$OUTPUT" > /dev/null ); then
   exit 0
fi
exec cp "$CACHED_OUTPUT" "$OUTPUT"
