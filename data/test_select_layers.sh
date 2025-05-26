#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {select_layers.pl}"
   exit 1
fi
TOOL=$1

set -euo pipefail
INPUT=$(mktemp)
OUTPUT=$(mktemp)

function die
{
   echo "$1"
   rm -f "$INPUT" "$OUTPUT"
   exit 1
}


# Try splitting small files.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg">
   <g
      inkscape:groupmode="layer"
      inkscape:label="ignored">
      <rect x="0" y="0" width="1" height="1" id="ignored_rect" />
   </g>
   <g
      inkscape:groupmode="layer"
      inkscape:label="selected">
      <rect x="0" y="0" width="1" height="1" id="selected_rect" />
   </g>
</svg>
EOT

perl "$TOOL" "selected" "output.png" "$INPUT" > "$OUTPUT"
if ! ( grep -q -F "selected_rect" "$OUTPUT" ); then
   die "$LINENO: expected selected layer not found"
fi
if ( grep -q -F "ignored_rect" "$OUTPUT" ); then
   die "$LINENO: found unexpected ignored layer"
fi

# Verify that attributes are canonicalized.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg">
   <g
      inkscape:groupmode="layer"
      inkscape:label="g1"
      style="display:none">
      <rect x="0" y="0" width="1" height="1" id="r1" />
   </g>
   <g
      inkscape:groupmode="layer"
      inkscape:label="g2"
      style="opacity:0">
      <rect x="0" y="0" width="1" height="1" id="r2" />
   </g>
   <g
      inkscape:groupmode="layer"
      inkscape:label="g3"
      sodipodi:insensitive="false">
      <rect x="0" y="0" width="1" height="1" id="r3" />
   </g>
</svg>
EOT

perl "$TOOL" "g.*" "output.png" "$INPUT" > "$OUTPUT"
if ( grep -q -F "display:none" "$OUTPUT" ); then
   die "$LINENO: found unexpected display style"
fi
if ( grep -q -F "opacity:0.0" "$OUTPUT" ); then
   die "$LINENO: found unexpected opacity style"
fi
LOCK_COUNT=$(sed -e 's/sodipodi:insensitive="true"/LOCKED\n/g' "$OUTPUT" \
             | grep -F "LOCKED" | wc -l)
if [[ "$LOCK_COUNT" -ne "3" ]]; then
   die "$LINENO: expecting 3 locked layers, got $LOCK_COUNT"
fi

# Check large file support.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg">
   <g
      inkscape:groupmode="layer"
      inkscape:label="ignored"
      style="display:none">
EOT
perl -e 'print "<rect x=\"0\" y=\"0\" width=\"1\" height=\"1\" />" x 1000000;' \
   >> "$INPUT"
cat <<EOT >> "$INPUT"
   </g>
   <g
      inkscape:groupmode="layer"
      inkscape:label="selected">
      <rect x="0" y="0" width="1" height="1" id="selected_rect" />
   </g>
</svg>
EOT
perl "$TOOL" "selected" "output.png" "$INPUT" > "$OUTPUT"
if ! ( grep -q -F "selected_rect" "$OUTPUT" ); then
   die "$LINENO: missing selected layer"
fi


# Cleanup.
rm -f "$INPUT" "$OUTPUT"
exit 0
