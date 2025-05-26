#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {crop_table.exe}"
   exit 1
fi
TOOL=$1
TEST_DIR=$(mktemp -d)
EXPECTED="$TEST_DIR/expected.png"
ACTUAL="$TEST_DIR/actual.png"

set -euo pipefail

function die
{
   echo "$1"
   rm -rf "$TEST_DIR"
   exit 1
}

function check_output
{
   local test_id=$1

   # Compare expected image in two steps (pixel and alpha).
   pngtopnm "$EXPECTED" | ppmtopgm -plain > "$TEST_DIR/expected.txt"
   pngtopnm "$ACTUAL" | ppmtopgm -plain > "$TEST_DIR/actual.txt"
   if ! ( diff -w "$TEST_DIR/expected.txt" "$TEST_DIR/actual.txt" ); then
      die "FAIL: $test_id: pixels mismatched"
   fi
   pngtopnm -alpha "$EXPECTED" | ppmtopgm -plain > "$TEST_DIR/expected.txt"
   pngtopnm -alpha "$ACTUAL" | ppmtopgm -plain > "$TEST_DIR/actual.txt"
   if ! ( diff -w "$TEST_DIR/expected.txt" "$TEST_DIR/actual.txt" ); then
      die "FAIL: $test_id: alpha mismatched"
   fi
}


# Create input image.
# x=0          5          10         15         20
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0   # y=0
#   0 1 1 1 0  0 2 2 2 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 1 1 1 0  0 2 2 2 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0   # y=4
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0   # y=8
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0   # y=12
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
#
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0   # y=16
#   0 0 0 0 0  0 0 0 0 0  0 3 3 3 0  0 4 4 4 0  0 5 5 5 0
#   0 0 0 0 0  0 0 0 0 0  0 3 3 3 0  0 4 4 4 0  0 5 5 5 0
#   0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
pgmmake 0 25 20 > "$TEST_DIR/z.pgm"
pnmtopng -alpha="$TEST_DIR/z.pgm" "$TEST_DIR/z.pgm" > "$TEST_DIR/blank.png"
convert \
   "$TEST_DIR/blank.png" \
   -fill "xc:#010101" -draw "rectangle 1,1 3,2" \
   -fill "xc:#020202" -draw "rectangle 6,1 8,2" \
   -fill "xc:#030303" -draw "rectangle 11,17 13,18" \
   -fill "xc:#040404" -draw "rectangle 16,17 18,18" \
   -fill "xc:#050505" -draw "rectangle 21,17 23,18" \
   "$TEST_DIR/input.png"

# No-op crop, input image should pass through unchanged.
"./$TOOL" 25 20 25 20 0 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
cp "$TEST_DIR/input.png" "$TEST_DIR/expected.png"
check_output "$LINENO: single tile no-op"

"./$TOOL" 5 4 5 4 0 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
cp "$TEST_DIR/input.png" "$TEST_DIR/expected.png"
check_output "$LINENO: multi-tile no-op"

# Try cropping the image as one single tile.
convert "$TEST_DIR/input.png" -crop "25x19+0+0" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 25 19 0 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile bottom edge 1"

convert "$TEST_DIR/input.png" -crop "25x18+0+0" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 25 18 0 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile bottom edge 2"

convert "$TEST_DIR/input.png" -crop "24x20+0+0" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 24 20 0 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile right edge 1"

convert "$TEST_DIR/input.png" -crop "23x20+0+0" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 23 20 0 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile right edge 2"

convert "$TEST_DIR/input.png" -crop "25x19+0+1" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 25 19 0 1 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile top edge 1"

convert "$TEST_DIR/input.png" -crop "25x18+0+2" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 25 18 0 2 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile top edge 2"

convert "$TEST_DIR/input.png" -crop "24x20+1+0" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 24 20 1 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile left edge 1"

convert "$TEST_DIR/input.png" -crop "23x20+2+0" "$TEST_DIR/expected.png"
"./$TOOL" 25 20 23 20 2 0 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: single tile left edge 2"

# Try cropping all edges.
# x=  0          3          6          9          12
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - 1 1 1 -  - 2 2 2 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -   # y=0
#   - 1 1 1 -  - 2 2 2 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -   # y=2
#   - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -   # y=4
#   - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -   # y=6
#   - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -  - 0 0 0 -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - 0 0 0 -  - 0 0 0 -  - 3 3 3 -  - 4 4 4 -  - 5 5 5 -   # y=8
#   - 0 0 0 -  - 0 0 0 -  - 3 3 3 -  - 4 4 4 -  - 5 5 5 -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
convert \
   "(" "$TEST_DIR/blank.png" -crop "15x10+0+0" ")" \
   -fill "xc:#010101" -draw "rectangle 0,0 2,1" \
   -fill "xc:#020202" -draw "rectangle 3,0 5,1" \
   -fill "xc:#030303" -draw "rectangle 6,8 8,9" \
   -fill "xc:#040404" -draw "rectangle 9,8 11,9" \
   -fill "xc:#050505" -draw "rectangle 12,8 14,9" \
   "$TEST_DIR/expected.png"

"./$TOOL" 5 4 3 2 1 1 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: all edges"

# Try a different crop offset.
# x=    0          3          6          9          12
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - 1 1 0  - - 2 2 0  - - 0 0 0  - - 0 0 0  - - 0 0 0   # y=0
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - 0 0 0  - - 0 0 0  - - 0 0 0  - - 0 0 0  - - 0 0 0   # y=1
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - 0 0 0  - - 0 0 0  - - 0 0 0  - - 0 0 0  - - 0 0 0   # y=2
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - 0 0 0  - - 0 0 0  - - 0 0 0  - - 0 0 0  - - 0 0 0   # y=3
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - 0 0 0  - - 0 0 0  - - 3 3 0  - - 4 4 0  - - 5 5 0   # y=4
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
#   - - - - -  - - - - -  - - - - -  - - - - -  - - - - -
convert \
   "(" "$TEST_DIR/blank.png" -crop "15x5+0+0" ")" \
   -fill "xc:#010101" -draw "rectangle 0,0 1,0" \
   -fill "xc:#020202" -draw "rectangle 3,0 4,0" \
   -fill "xc:#030303" -draw "rectangle 6,4 7,4" \
   -fill "xc:#040404" -draw "rectangle 9,4 10,4" \
   -fill "xc:#050505" -draw "rectangle 12,4 13,4" \
   "$TEST_DIR/expected.png"

"./$TOOL" 5 4 3 1 2 1 < "$TEST_DIR/input.png" > "$TEST_DIR/actual.png"
check_output "$LINENO: offset"

# Check invalid arguments.
"./$TOOL" 6 4 1 1 0 0 \
   < "$TEST_DIR/input.png" \
   > "$TEST_DIR/actual.png" \
   2> "$TEST_DIR/error.txt" && die "$LINENO: unexpected success"
if ! ( grep -qF "Image dimension" "$TEST_DIR/error.txt" ); then
   die "$LINENO: missing error message"
fi

"./$TOOL" 5 4 6 4 0 0 \
   < "$TEST_DIR/input.png" \
   > "$TEST_DIR/actual.png" \
   2> "$TEST_DIR/error.txt" && die "$LINENO: unexpected success"
if ! ( grep -qF "Invalid crop parameters" "$TEST_DIR/error.txt" ); then
   die "$LINENO: missing error message"
fi

# Cleanup.
rm -rf "$TEST_DIR"
exit 0
