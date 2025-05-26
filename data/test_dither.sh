#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {dither.exe}"
   exit 1
fi
TOOL=$1

set -euo pipefail
INPUT_PIXELS=$(mktemp)
INPUT_ALPHA=$(mktemp)
INPUT_IMAGE=$(mktemp)
EXPECTED_PIXELS=$(mktemp)
EXPECTED_ALPHA=$(mktemp)
ACTUAL_OUTPUT=$(mktemp)

function die
{
   echo "$1"
   rm -f "$INPUT_PIXELS" "$INPUT_ALPHA" "$INPUT_IMAGE"
   rm -f "$EXPECTED_PIXELS" "$EXPECTED_ALPHA" "$ACTUAL_OUTPUT"
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
P1
4 3
1 1 1 1
0 0 0 0
1 0 1 0
EOT
cat <<EOT > "$INPUT_ALPHA"
P1
4 3
1 0 0 1
1 0 1 0
1 0 0 1
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
4 3
1 1 1 1
1 0 1 0
1 0 1 1
EOT
cp "$INPUT_ALPHA" "$EXPECTED_ALPHA"

"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: file in + file out"

cat "$INPUT_IMAGE" | "./$TOOL" - "$ACTUAL_OUTPUT"
check_output "$LINENO: stdin + file out"

"./$TOOL" "$INPUT_IMAGE" - > "$ACTUAL_OUTPUT"
check_output "$LINENO: file in + stdout"

cat "$INPUT_IMAGE" | "./$TOOL" - - > "$ACTUAL_OUTPUT"
check_output "$LINENO: stdin + stdout"

# ................................................................
# Test dither pattern.

ppmmake rgb:ff/ff/ff 8 8 | pnmtopng > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
8 8
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0
EOT
cp "$EXPECTED_PIXELS" "$EXPECTED_ALPHA"
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=1 alpha=1"

ppmmake rgb:80/80/80 8 8 | pnmtopng > "$INPUT_IMAGE"
CAT <<EOT > "$EXPECTED_PIXELS"
P1
8 8
1 0 1 0 1 0 1 0
0 1 0 1 0 1 0 1
1 0 1 0 1 0 1 0
0 1 0 1 0 1 0 1
1 0 1 0 1 0 1 0
0 1 0 1 0 1 0 1
1 0 1 0 1 0 1 0
0 1 0 1 0 1 0 1
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0.5 alpha=1"

ppmmake rgb:00/00/00 8 8 | pnmtopng > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
8 8
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0 alpha=1"

ppmmake rgb:40/40/40 8 8 | pnmtopng > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
8 8
1 1 1 1 1 1 1 1
0 1 0 1 0 1 0 1
1 1 1 1 1 1 1 1
0 1 0 1 0 1 0 1
1 1 1 1 1 1 1 1
0 1 0 1 0 1 0 1
1 1 1 1 1 1 1 1
0 1 0 1 0 1 0 1
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0.25 alpha=1"

ppmmake rgb:c0/c0/c0 8 8 | pnmtopng > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
8 8
1 0 1 0 1 0 1 0
0 0 0 0 0 0 0 0
1 0 1 0 1 0 1 0
0 0 0 0 0 0 0 0
1 0 1 0 1 0 1 0
0 0 0 0 0 0 0 0
1 0 1 0 1 0 1 0
0 0 0 0 0 0 0 0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0.75 alpha=1"

# ................................................................
# Test translucent black.

ppmmake rgb:00/00/00 16 4 > "$INPUT_PIXELS"
pgmmake 1 16 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
16 4
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0 alpha=1"

pgmmake 0 16 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0 alpha=0"

pgmmake 0.5 16 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
  0 255   0 255   0 255   0 255   0 255   0 255   0 255   0 255
255   0 255   0 255   0 255   0 255   0 255   0 255   0 255   0
  0 255   0 255   0 255   0 255   0 255   0 255   0 255   0 255
255   0 255   0 255   0 255   0 255   0 255   0 255   0 255   0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0 alpha=0.5"

cat <<EOT > "$INPUT_ALPHA"
P2
16 4
255
64 64 64 64 64 64 64 64  192 192 192 192 192 192 192 192
64 64 64 64 64 64 64 64  192 192 192 192 192 192 192 192
64 64 64 64 64 64 64 64  192 192 192 192 192 192 192 192
64 64 64 64 64 64 64 64  192 192 192 192 192 192 192 192
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
  0   0   0   0   0   0   0   0     0 255   0 255   0 255   0 255
255   0 255   0 255   0 255   0   255 255 255 255 255 255 255 255
  0   0   0   0   0   0   0   0     0 255   0 255   0 255   0 255
255   0 255   0 255   0 255   0   255 255 255 255 255 255 255 255
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0 alpha=0.25+0.75"

# ................................................................
# Test translucent white.

ppmmake rgb:ff/ff/ff 16 4 > "$INPUT_PIXELS"
pgmmake 1 16 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
16 4
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=1 alpha=1"

pgmmake 0 16 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
16 4
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=1 alpha=0"

pgmmake 0.5 16 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
16 4
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0
0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0
0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
  0 255   0 255   0 255   0 255   0 255   0 255   0 255   0 255
255   0 255   0 255   0 255   0 255   0 255   0 255   0 255   0
  0 255   0 255   0 255   0 255   0 255   0 255   0 255   0 255
255   0 255   0 255   0 255   0 255   0 255   0 255   0 255   0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=1 alpha=0.5"

cat <<EOT > "$INPUT_ALPHA"
P2
16 4
255
192 192 192 192 192 192 192 192  64 64 64 64 64 64 64 64
192 192 192 192 192 192 192 192  64 64 64 64 64 64 64 64
192 192 192 192 192 192 192 192  64 64 64 64 64 64 64 64
192 192 192 192 192 192 192 192  64 64 64 64 64 64 64 64
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
16 4
1 0 1 0 1 0 1 0 1 1 1 1 1 1 1 1
0 0 0 0 0 0 0 0 0 1 0 1 0 1 0 1
1 0 1 0 1 0 1 0 1 1 1 1 1 1 1 1
0 0 0 0 0 0 0 0 0 1 0 1 0 1 0 1
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
16 4
255
  0 255   0 255   0 255   0 255     0   0   0   0   0   0   0   0
255 255 255 255 255 255 255 255   255   0 255   0 255   0 255   0
  0 255   0 255   0 255   0 255     0   0   0   0   0   0   0   0
255 255 255 255 255 255 255 255   255   0 255   0 255   0 255   0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=1 alpha=0.75+0.25"

# ................................................................
# Test translucent gray.

ppmmake rgb:c0/c0/c0 8 4 > "$INPUT_PIXELS"
pgmmake 1 8 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
8 4
1 0 1 0  1 0 1 0
0 0 0 0  0 0 0 0
1 0 1 0  1 0 1 0
0 0 0 0  0 0 0 0
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
8 4
255
255 255 255 255  255 255 255 255
255 255 255 255  255 255 255 255
255 255 255 255  255 255 255 255
255 255 255 255  255 255 255 255
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0.75 alpha=1"

pgmmake 0.5 8 4 > "$INPUT_ALPHA"
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"
cat <<EOT > "$EXPECTED_PIXELS"
P1
8 4
1 0 1 0  1 0 1 0
0 1 0 1  0 1 0 1
1 0 1 0  1 0 1 0
0 1 0 1  0 1 0 1
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
8 4
255
  0 255   0 255    0 255   0 255
255   0 255   0  255   0 255   0
  0 255   0 255    0 255   0 255
255   0 255   0  255   0 255   0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: pixel=0.75 alpha=0.5"

# ................................................................
# Test automatic conversion of color to grayscale.

ppmmake rgb:ff/ff/ff 3 4 > "$INPUT_PIXELS"
cat <<EOT > "$INPUT_ALPHA"
P2
3 4
255
255 255 255
255 255 255
0 0 0
0 0 0
EOT
pnmtopng -alpha="$INPUT_ALPHA" "$INPUT_PIXELS" > "$INPUT_IMAGE"

cat <<EOT > "$EXPECTED_PIXELS"
P1
3 4
0 0 0
0 0 0
1 1 1
1 1 1
EOT
cat <<EOT > "$EXPECTED_ALPHA"
P2
3 4
255
255 255 255
255 255 255
0 0 0
0 0 0
EOT
"./$TOOL" "$INPUT_IMAGE" "$ACTUAL_OUTPUT"
check_output "$LINENO: rgb"

# ................................................................
# Cleanup.
rm -f "$INPUT_PIXELS" "$INPUT_ALPHA" "$INPUT_IMAGE"
rm -f "$EXPECTED_PIXELS" "$EXPECTED_ALPHA" "$ACTUAL_OUTPUT"
exit 0
