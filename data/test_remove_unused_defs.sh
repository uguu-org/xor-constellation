#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {remove_unused_defs.pl}"
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
      <linearGradient id="remove_in_pass2" />
      <radialGradient id="remove_in_pass1" xlink:href="#remove_in_pass2" />
      <linearGradient id="keep1" />
      <linearGradient id="used_via_xlink" />
      <radialGradient id="keep2" xlink:href="#used_via_xlink" />
   </defs>
   <rect style="fill:url(#keep1)" />
   <rect style="fill:url(#keep2)" />
</svg>
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><defs><linearGradient id="keep1"/><linearGradient id="used_via_xlink"/><radialGradient id="keep2" xlink:href="#used_via_xlink"/></defs><rect style="fill:url(#keep1)"/><rect style="fill:url(#keep2)"/></svg>
EOT

# Run tool.
"./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT" || die "$LINENO: $TOOL failed: $?"
if ! ( diff -w -B "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "$LINENO: Output mismatched"
fi

# Try again to confirm that output is idempotent.
mv -f "$ACTUAL_OUTPUT" "$EXPECTED_OUTPUT"
"./$TOOL" "$INPUT" | "./$TOOL" > "$ACTUAL_OUTPUT" \
   || die "$LINENO: $TOOL failed: $?"
if ! ( diff -w -B "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "$LINENO: Output is not idempotent"
fi

# Verify that whitespaces are always stripped even if we didn't remove
# any definitions.
cat <<EOT > "$INPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">
   <defs>
      <linearGradient id="keep" />
   </defs>
   <rect style="fill:url(#keep)" />
</svg>
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><defs><linearGradient id="keep"/></defs><rect style="fill:url(#keep)"/></svg>
EOT

"./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT" || die "$LINENO: $TOOL failed: $?"
if ! ( diff "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "$LINENO: Output mismatched"
fi

# Cleanup.
rm -f "$INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
exit 0
