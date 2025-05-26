#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {generate_build_graph.pl}"
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

# Generate input.
cat <<EOT > "$INPUT"
# Comment should be removed.
variable1 = value1
variable2 ?= value2
variable3 = line \
   continuation

all: target1 target2 cycle

target1:
	\$(MAKE) -C subdir

target2: \$(variable1) \$(variable2) \$(variable3)
	echo \$^ > \$@

# Don't care about circular dependencies.
cycle: cycle
EOT


# Run tool.
"./$TOOL" "$INPUT" > "$OUTPUT" || die "$LINENO: $TOOL failed: $?"

# Check basic line parsing functionality.
if ( grep -qF 'Comments should be removed' "$OUTPUT" ); then
   die "$LINENO: found unexpected comments"
fi
if ! ( grep -qF 'line continuation' "$OUTPUT" ); then
   die "$LINENO: failed to parse line continuation"
fi

# Check that first target is selected.
if ! ( grep -qF 'Build target = all' "$OUTPUT" ); then
   die "$LINENO: failed to select build target"
fi

# Check variable expansion.
if ( grep -qF '$(variable1)' "$OUTPUT" ); then
   die "$LINENO: failed to expand variable1"
fi
if ( grep -qF '$(variable2)' "$OUTPUT" ); then
   die "$LINENO: failed to expand variable2"
fi
if ! ( grep -qF 'echo value1 value2' "$OUTPUT" ); then
   die "$LINENO: failed to expand \$^"
fi
if ! ( grep -qF '> target2' "$OUTPUT" ); then
   die "$LINENO: failed to expand \$@"
fi
if ! ( grep -qF '$(MAKE)' "$OUTPUT" ); then
   die "$LINENO: unexpected expansion"
fi

# Check that there is at least one node and one edge in output graph.
if ! ( grep -qE 'n0.*label.*tooltip' "$OUTPUT" ); then
   die "$LINENO: missing nodes"
fi
if ! ( grep -qE 'n1 -> n0.*edgetooltip' "$OUTPUT" ); then
   die "$LINENO: missing edges"
fi


# Run tool again, this time selecting a different target.
"./$TOOL" "$INPUT" target2 > "$OUTPUT" || die "$LINENO: $TOOL failed: $?"

if ! ( grep -qF 'Build target = target2' "$OUTPUT" ); then
   die "$LINENO: failed to select build target"
fi
if ( grep -qF 'target1' "$OUTPUT" ); then
   die "$LINENO: unexpected inclusion of unrelated target"
fi


# Cleanup.
rm -f "$INPUT" "$OUTPUT"
exit 0
