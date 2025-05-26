#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {cleanup_styles.pl}"
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
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">
<defs>
   <clipPath>
      <path id="clip_path_test" style="fill:none;stroke:#ffffff;stroke-width:1;stroke-linecap:round;stroke-linejoin:round" />
   </clipPath>
</defs>
<g>
   <rect id="line_number_sync_test1" style="fill:red;stroke-opacity:0.1" />
   <rect id="line_number_sync_test2" style="fill:red;stroke-opacity:0.1" />
   <rect
      id="line_number_sync_test3"
      style="fill:red;stroke-opacity:0.1" />
   <rect id="line_number_sync_test4" style="fill:red;stroke-opacity:0.1" />
   <rect
      style="fill:red;stroke-opacity:0.1"
      id="line_number_sync_test5" />
</g>
<g>
   <rect style="fill:#111111;stroke:#222222;fill-opacity:0.1;stroke-opacity:0.2;paint-order:stroke fill markers" />
   <rect style="fill:#333333;stroke:none;fill-opacity:0.1;stroke-opacity:0.2;paint-order:stroke fill markers" />
   <rect style="fill:none;stroke:#444444;fill-opacity:0.1;stroke-opacity:0.2;paint-order:stroke fill markers" />
   <rect
      style="fill:none;stroke:none;fill-opacity:0.1;stroke-opacity:0.2;paint-order:stroke fill markers"
   />
   <rect style="fill-opacity:0.1" />
   <rect style="stroke-opacity:0.1" />
   <rect style="stroke-dasharray:none;stroke-dashoffset:0.799748;stroke-opacity:1" />
   <rect style="stroke-dashoffset:0.799748;stroke-opacity:1" />
   <rect style="opacity:1;-inkscape-stroke:none" />
   <rect style="vector-effect:non-scaling-stroke;fill:#ff0000;-inkscape-stroke:hairline" />
   <rect style="stroke:#000000;-inkscape-stroke:none" />
</g>
<g>
   <text style="font-size:11px;-inkscape-font-specification:'sans-serif, Normal'">
      <tspan style="font-size:22px">3</tspan>
   </text>
   <rect style="font-size:44px;letter-spacing:4px;word-spacing:4px" />
</g>
<g style="stroke:#111111">
   <rect id="inherit1" style="stroke:none" />
   <g style="stroke:none">
      <rect id="inherit2" style="stroke:none" />
   </g>
   <g style="stroke:#222222;stroke-dasharray:1,2">
      <rect id="inherit3" style="stroke-dasharray:none" />
   </g>
</g>
<g style="display:none">
   <g style="display:inline">
      <rect id="display-not-inherited" style="fill:#000000" />
   </g>
</g>
<g>
   <rect style="" />
   <rect
      style=""
   />
   <rect
      id="id"
      style="" />
   <rect
      style=""
      id="id" />
   <g style="">
   </g>
   <g
      style="">
   </g>
</g>
<g>
   <rect clip-path="none" />
   <rect
      clip-path="none" />
   <rect
      clip-path="none"
      id="id" />
</g>
<g>
   <rect sodipodi:nodetypes="ccc" />
   <rect
      sodipodi:nodetypes="cccc" />
   <rect
      sodipodi:nodetypes="ccccc"
      id="id" />
   <rect sodipodi:nodetypes="csc" />
   <rect
      sodipodi:nodetypes="sccc" />
   <rect
      sodipodi:nodetypes="ccccs"
      id="id" />
</g>
<g>
   <rect
      clip-path="none"
      sodipodi:nodetypes="cccccc"
      style="" />
   <rect
      style=""
      clip-path="none"
      sodipodi:nodetypes="cccccc" />
   <rect
      style=""
      sodipodi:nodetypes="cccccc"
      clip-path="none" />
</g>
</svg>
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">
<defs>
   <clipPath>
      <path id="clip_path_test" style="fill:none;stroke:#ffffff;stroke-width:1;stroke-linejoin:round" />
   </clipPath>
</defs>
<g>
   <rect id="line_number_sync_test1" style="fill:red" />
   <rect id="line_number_sync_test2" style="fill:red" />
   <rect
      id="line_number_sync_test3"
      style="fill:red" />
   <rect id="line_number_sync_test4" style="fill:red" />
   <rect
      style="fill:red"
      id="line_number_sync_test5" />
</g>
<g>
   <rect style="fill:#111111;stroke:#222222;fill-opacity:0.1;stroke-opacity:0.2;paint-order:stroke fill markers" />
   <rect style="fill:#333333;fill-opacity:0.1" />
   <rect style="fill:none;stroke:#444444;stroke-opacity:0.2" />
   <rect
      style="fill:none"
   />
   <rect style="fill-opacity:0.1" />
   <rect />
   <rect />
   <rect />
   <rect />
   <rect style="fill:#ff0000" />
   <rect style="stroke:#000000" />
</g>
<g>
   <text style="font-size:11px">
      <tspan style="font-size:22px">3</tspan>
   </text>
   <rect />
</g>
<g style="stroke:#111111">
   <rect id="inherit1" style="stroke:none" />
   <g style="stroke:none">
      <rect id="inherit2" />
   </g>
   <g style="stroke:#222222;stroke-dasharray:1,2">
      <rect id="inherit3" style="stroke-dasharray:none" />
   </g>
</g>
<g style="display:none">
   <g>
      <rect id="display-not-inherited" style="fill:#000000" />
   </g>
</g>
<g>
   <rect />
   <rect
   />
   <rect
      id="id" />
   <rect
      id="id" />
   <g>
   </g>
   <g>
   </g>
</g>
<g>
   <rect />
   <rect />
   <rect
      id="id" />
</g>
<g>
   <rect />
   <rect />
   <rect
      id="id" />
   <rect sodipodi:nodetypes="csc" />
   <rect
      sodipodi:nodetypes="sccc" />
   <rect
      sodipodi:nodetypes="ccccs"
      id="id" />
</g>
<g>
   <rect
   />
   <rect
   />
   <rect
   />
</g>
</svg>
EOT

# Run tool.
"./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT"

if ! ( diff -w -B "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "Output mismatched"
fi

# Try again to confirm that output is idempotent.
mv -f "$ACTUAL_OUTPUT" "$EXPECTED_OUTPUT"
"./$TOOL" "$INPUT" | "./$TOOL" > "$ACTUAL_OUTPUT"
if ! ( diff -w -B "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "Output is not idempotent"
fi

# Verify that unsupported file formats are flagged.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">
<g xml:space="preserve"
   style="fill:none"><g style="stroke:none"></g></g>
</svg>
EOT
"./$TOOL" "$INPUT" >& "$ACTUAL_OUTPUT" || true
if ! ( grep -q -F "xml:space" "$ACTUAL_OUTPUT" ); then
   die "Missing expected message regarding xml:space"
fi
if ! ( grep -q -F "reformat" "$ACTUAL_OUTPUT" ); then
   die "Missing expected error message"
fi

cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">
<g style="fill:none"><g style="stroke:none"></g></g>
</svg>
EOT
"./$TOOL" "$INPUT" >& "$ACTUAL_OUTPUT" || true
if ( grep -q -F "xml:space" "$ACTUAL_OUTPUT" ); then
   die "Unexpected message regarding xml:space"
fi
if ! ( grep -q -F "rewrite" "$ACTUAL_OUTPUT" ); then
   die "Missing expected error message"
fi

# Cleanup.
rm -f "$INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
exit 0
