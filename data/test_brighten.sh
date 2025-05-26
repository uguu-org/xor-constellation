#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {brighten.pl}"
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

# Generate test data.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg"
   width="1024"
   height="1024"
   viewBox="0 0 1024 1024">
   <g inkscape:groupmode="layer"
      inkscape:label="ignored">
      <rect style="fill:#808080" x="0" y="0" width="10" height="20" />
   </g>
   <g inkscape:groupmode="layer"
      inkscape:label="matched">
      <rect style="fill:#102030" x="20" y="0" width="10" height="10" />
      <rect style="stroke:#405060" x="40" y="0" width="10" height="10" />
   </g>
</svg>
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
   <g inkscape:groupmode="layer" inkscape:label="ignored">
      <rect style="fill:#808080" x="0" y="0" width="10" height="20" />
   </g>
   <g inkscape:groupmode="layer" inkscape:label="matched">
      <rect style="fill:#878f97" x="20" y="0" width="10" height="10" />
      <rect style="stroke:#9fa7af" x="40" y="0" width="10" height="10" />
   </g>
</svg>
EOT

# Run tool.
"./$TOOL" "matched" "$INPUT" > "$ACTUAL_OUTPUT"

if ! ( diff -w -B "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "Output mismatched"
fi

# Cleanup.
rm -f "$INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
exit 0
