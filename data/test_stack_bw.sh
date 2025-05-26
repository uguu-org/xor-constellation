#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {stack_bw.exe}"
   exit 1
fi
TOOL=$1

set -euo pipefail
TEST_DIR=$(mktemp -d)
INPUT_PIXELS="$TEST_DIR/input_pixels.ppm"
INPUT_ALPHA="$TEST_DIR/input_alpha.ppm"
INPUT_IMAGE="$TEST_DIR/input.png"
ADD_INPUT_PIXELS="$TEST_DIR/add_input_pixels.ppm"
ADD_INPUT_ALPHA="$TEST_DIR/add_input_alpha.ppm"
ADD_INPUT_IMAGE="$TEST_DIR/add_input.png"
ADD2_INPUT_PIXELS="$TEST_DIR/add2_input_pixels.ppm"
ADD2_INPUT_ALPHA="$TEST_DIR/add2_input_alpha.ppm"
ADD2_INPUT_IMAGE="$TEST_DIR/add2_input.png"
EXPECTED_PIXELS="$TEST_DIR/expected_pixels.ppm"
EXPECTED_ALPHA="$TEST_DIR/expected_alpha.ppm"
ACTUAL_OUTPUT="$TEST_DIR/actual.png"


function die
{
   echo "$1"
   rm -rf "$TEST_DIR"
   exit 1
}

function check_output
{
   local test_id=$1
   local expected=$(ppmtoppm < "$EXPECTED_PIXELS" | ppmtopgm -plain)
   local actual=$(pngtopnm "$ACTUAL_OUTPUT" | ppmtopgm -plain)
   if [[ "$expected" != "$actual" ]]; then
      echo "Expected pixels:"
      echo "$expected"
      echo "Actual pixels:"
      echo "$actual"
      die "FAIL: $test_id"
   fi
   expected=$(ppmtoppm < "$EXPECTED_ALPHA" | ppmtopgm -plain)
   actual=$(pngtopnm -alpha "$ACTUAL_OUTPUT" | ppmtopgm -plain)
   if [[ "$expected" != "$actual" ]]; then
      echo "Expected alpha:"
      echo "$expected"
      echo "Actual alpha:"
      echo "$actual"
      die "FAIL: $test_id"
   fi
}


# ................................................................
# Test basic input/output.

cat <<EOT > "$INPUT_PIXELS"
P2
4 3
255
255 255 255 255
0   0   0   0
255 0   255 0
EOT
cat <<EOT > "$INPUT_ALPHA"
P2
4 3
255
255 0 0   255
255 0 255 0
255 0 0   255
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cp "$INPUT_PIXELS" "$EXPECTED_PIXELS"
cp "$INPUT_ALPHA" "$EXPECTED_ALPHA"

"./$TOOL" "$INPUT_IMAGE" > "$ACTUAL_OUTPUT"
check_output "$LINENO: single file"

"./$TOOL" "$INPUT_IMAGE" "$INPUT_IMAGE" > "$ACTUAL_OUTPUT"
check_output "$LINENO: same file"


# ................................................................
# Check sizes.

cat <<EOT > "$INPUT_PIXELS"
P2
3 3
255
255 255 255
255 255 255
255 255 255
EOT
pnmtopng "$INPUT_PIXELS" > "$INPUT_IMAGE"

cat <<EOT > "$ADD_INPUT_PIXELS"
P2
4 3
255
255 255 255 255
255 255 255 255
255 255 255 255
EOT
pnmtopng "$ADD_INPUT_PIXELS" > "$ADD_INPUT_IMAGE"

"./$TOOL" "$INPUT_IMAGE" "$ADD_INPUT_IMAGE" > /dev/null 2>&1 \
   && die "$LINENO: width check"

cat <<EOT > "$ADD_INPUT_PIXELS"
P2
3 4
255
255 255 255
255 255 255
255 255 255
255 255 255
EOT
pnmtopng "$ADD_INPUT_PIXELS" > "$ADD_INPUT_IMAGE"

"./$TOOL" "$INPUT_IMAGE" "$ADD_INPUT_IMAGE" > /dev/null 2>&1 \
   && die "$LINENO: height check"


# ................................................................
# Stack two images.

cat <<EOT > "$INPUT_PIXELS"
P2
4 3
255
255 0   255 0
0   255 0   255
255 0   255 0
EOT
cat <<EOT > "$INPUT_ALPHA"
P2
4 3
255
255 255 255 255
255 255 255 255
0   0   0   0
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"

cat <<EOT > "$ADD_INPUT_PIXELS"
P2
4 3
255
0   0   0   255
0   0   255 0
255 255 0   0
EOT
cat <<EOT > "$ADD_INPUT_ALPHA"
P2
4 3
255
0   0   0   255
0   0   0   255
255 255 0   255
EOT
pnmtopng -alpha="$ADD_INPUT_ALPHA" "$ADD_INPUT_PIXELS" > "$ADD_INPUT_IMAGE"

cat <<EOT > "$EXPECTED_PIXELS"
P2
4 3
255
255 0   255 255
0   255 0   0
255 255 255 0
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
4 3
255
255 255 255 255
255 255 255 255
255 255 0   255
EOT

"./$TOOL" "$INPUT_IMAGE" "$ADD_INPUT_IMAGE" > "$ACTUAL_OUTPUT"
check_output "$LINENO: stack 2"


# ................................................................
# Stack three images.

cat <<EOT > "$INPUT_PIXELS"
P2
6 3
255
0 255 0 0 0 0
0 255 0 0 0 0
0 255 0 0 0 0
EOT
cat <<EOT > "$INPUT_ALPHA"
P2
6 3
255
255 255 255 255 255 255
0   0   0   0   0   0
0   0   0   0   0   0
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"

cat <<EOT > "$ADD_INPUT_PIXELS"
P2
6 3
255
0 0 0 255 0 0
0 0 0 255 0 0
0 0 0 255 0 0
EOT
cat <<EOT > "$ADD_INPUT_ALPHA"
P2
6 3
255
0   0   0   0   0   0
255 255 255 255 255 255
0   0   0   0   0   0
EOT
pnmtopng -alpha="$ADD_INPUT_ALPHA" "$ADD_INPUT_PIXELS" > "$ADD_INPUT_IMAGE"

cat <<EOT > "$ADD2_INPUT_PIXELS"
P2
6 3
255
0 0 0 0 0 255
0 0 0 0 0 255
0 0 0 0 0 255
EOT
cat <<EOT > "$ADD2_INPUT_ALPHA"
P2
6 3
255
0   0   0   0   0   0
0   0   0   0   0   0
255 255 255 255 255 255
EOT
pnmtopng -alpha="$ADD2_INPUT_ALPHA" "$ADD2_INPUT_PIXELS" > "$ADD2_INPUT_IMAGE"

cat <<EOT > "$EXPECTED_PIXELS"
P2
6 3
255
0   255 0   0   0   0
0   0   0   255 0   0
0   0   0   0   0   255
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
6 3
255
255 255 255 255 255 255
255 255 255 255 255 255
255 255 255 255 255 255
EOT

"./$TOOL" "$INPUT_IMAGE" "$ADD_INPUT_IMAGE" "$ADD2_INPUT_IMAGE" \
   > "$ACTUAL_OUTPUT"
check_output "$LINENO: stack 3"


# ................................................................
# Cleanup.
rm -rf "$TEST_DIR"
exit 0
