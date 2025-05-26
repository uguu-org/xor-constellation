#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {element_count.pl}"
   exit 1
fi
TOOL=$1

set -euo pipefail
INPUT=$(mktemp)
EXPECTED_OUTPUT=$(mktemp)
ACTUAL_OUTPUT=$(mktemp)

function die
{
   echo "$1"
   rm -f "$INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
   exit 1
}

# Generate input.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">
<g id="group 1 of 2">
   <g id="group 2 of 2">
      <rect id="rect 1 of 3" />
      <path
         id="path 1 of 1" />
      <rect
         id="rect 2 of 3" />
      <rect id="rect 3 of 3"
         />
   </g>
</g>
</svg>
EOT

# Generate expected output.
cat <<EOT > "$EXPECTED_OUTPUT"
g 2
path 1
rect 3
svg 1
TOTAL 7
EOT

# Run tool and check output.
"./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT" || die "$LINENO: Unexpected failure: $?"
if ! ( diff "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "$LINENO: Output mismatched"
fi

# Cleanup.
rm -f "$INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
exit 0
