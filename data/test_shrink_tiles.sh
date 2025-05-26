#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {shrink_tiles.exe}"
   exit 1
fi
TOOL=$1
TEST_DIR=$(mktemp -d)
INPUT="$TEST_DIR/input.png"
EXPECTED="$TEST_DIR/expected.txt"
ACTUAL="$TEST_DIR/actual.txt"

set -euo pipefail

function die
{
   echo "$1"
   rm -rf "$TEST_DIR"
   exit 1
}

function run_test
{
   local line_number=$1
   local cell_width=$2
   local cell_height=$3
   local expected_w=$4
   local expected_h=$5
   local expected_x=$6
   local expected_y=$7

   echo "$expected_w $expected_h $expected_x $expected_y" > "$EXPECTED"
   "./$TOOL" "$cell_width" "$cell_height" "$INPUT" > "$ACTUAL"
   if ! ( diff "$EXPECTED" "$ACTUAL" ); then
      die "Failed at line $line_number"
   fi

   "./$TOOL" "$cell_width" "$cell_height" - < "$INPUT" > "$ACTUAL"
   if ! ( diff "$EXPECTED" "$ACTUAL" ); then
      die "Failed at line $line_number (reading from stdin)"
   fi
}

# Generate input.
# 0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
# 0 1 1 0  0 0 0 0  0 3 0 0  0 4 0 0
# 0 1 1 0  0 2 2 0  0 3 0 0  0 4 0 0
# 0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
#
# 0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
# 0 5 5 0  0 0 0 0  0 0 6 0  0 7 0 0
# 0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
# 0 0 0 0  0 0 0 0  0 0 0 0  0 0 0 0
pgmmake 0 16 8 > "$TEST_DIR/z.pgm"
pnmtopng -alpha="$TEST_DIR/z.pgm" "$TEST_DIR/z.pgm" > "$TEST_DIR/blank.png"
convert \
   "$TEST_DIR/blank.png" \
   -fill "xc:#010101" -draw "rectangle 1,1 2,2" \
   -fill "xc:#020202" -draw "rectangle 5,2 6,2" \
   -fill "xc:#030303" -draw "rectangle 9,1 9,2" \
   -fill "xc:#040404" -draw "rectangle 13,1 13,2" \
   -fill "xc:#050505" -draw "rectangle 1,5 2,5" \
   -fill "xc:#060606" -draw "rectangle 10,5 10,5" \
   -fill "xc:#070707" -draw "rectangle 13,5 13,5" \
   "$TEST_DIR/input.png"

# Try different cell sizes.
run_test $LINENO  16 8  13 5 1 1
run_test $LINENO  8 8   6 5 1 1
run_test $LINENO  4 4   2 2 1 1

# Try another input to exercise different offsets.
# 0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
# 0 0 0 1 1  0 0 0 0 0  0 0 0 0 0
# 0 0 0 0 0  0 0 0 2 2  0 0 0 0 0
#
# 0 0 0 0 0  0 0 0 0 0  0 0 0 0 0
# 0 0 0 0 0  0 0 0 0 3  0 0 0 0 0
# 0 0 0 0 0  0 0 0 0 0  0 0 0 4 0
convert \
   "(" "$TEST_DIR/blank.png" -crop "15x6+0+0" ")" \
   -fill "xc:#010101" -draw "rectangle 3,1 4,1" \
   -fill "xc:#020202" -draw "rectangle 8,2 9,2" \
   -fill "xc:#030303" -draw "rectangle 9,4 9,4" \
   -fill "xc:#040404" -draw "rectangle 13,5 13,5" \
   "$TEST_DIR/input.png"

run_test $LINENO  15 6  11 5 3 1
run_test $LINENO  15 3  11 2 3 1
run_test $LINENO  5 3   2 2 3 1

# Try a few no-crop cases.
pgmmake 1 30 30 | pnmtopng > "$TEST_DIR/input.png"

run_test $LINENO  2 2   2 2 0 0
run_test $LINENO  3 3   3 3 0 0
run_test $LINENO  5 5   5 5 0 0
run_test $LINENO  10 6  10 6 0 0

# Try more no-crop cases with black pixels.  This verifies that we are
# checking the alpha channel as opposed to pixel color.
pgmmake 0 16 24 | pnmtopng > "$TEST_DIR/input.png"

run_test $LINENO  4 4   4 4 0 0
run_test $LINENO  8 3   8 3 0 0
run_test $LINENO  16 8  16 8 0 0

# Test error messages.
"./$TOOL" 7 2 "$TEST_DIR/input.png" > "$TEST_DIR/error.txt" \
   && die "$LINENO: unexpected success"
if ! ( grep -qF "Image dimension" "$TEST_DIR/error.txt" ); then
   die "$LINENO: missing error message"
fi

"./$TOOL" 5 11 "$TEST_DIR/input.png" > "$TEST_DIR/error.txt" \
   && die "$LINENO: unexpected success"
if ! ( grep -qF "Image dimension" "$TEST_DIR/error.txt" ); then
   die "$LINENO: missing error message"
fi

"./$TOOL" 4 4 "$TEST_DIR/blank.png" > "$TEST_DIR/error.txt"
if ! ( grep -qF "Input is completely blank" "$TEST_DIR/error.txt" ); then
   die "$LINENO: missing error message"
fi

# Cleanup.
rm -rf "$TEST_DIR"
exit 0
