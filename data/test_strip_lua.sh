#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {strip_lua.pl}"
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

# ................................................................

cat <<EOT > "$INPUT"
print(1)
--comment1
   print(2)
   -- comment2
	print(3)
	--comment3
print(4)  --comment4
--[[
comment5
--]]
x = "quote -- "
x = '-- quote'
x = "quote\"--quote"
x = 'quote\'--quote'
x = "quote -- quote"  -- comment6
------
print(6)
assert(1)
   assert(2)
	-- comment7 -- comment8
	assert(3)
not_assert(4)

local keep_var = 5
local keep_const <const> = 6
local discard_var = 7
local discard_const <const> = 8
local multiline_var =
   "always keep"
local function f()
   print("keep", keep_var, keep_const)
end
local function test_g()
   print("discard (second pass)")
end
local function test_f()
   print("discard (first pass)")
   test_g()
   return true
end
assert(test_f())
f()
local function unused_recursive_function()
   unused_recursive_function()
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
print(1)

   print(2)

	print(3)

print(4)



x = "quote -- "
x = '-- quote'
x = "quote\"--quote"
x = 'quote\'--quote'
x = "quote -- quote"

print(6)




not_assert(4)

local keep_var = 5
local keep_const <const> = 6


local multiline_var =
   "always keep"
local function f()
   print("keep", keep_var, keep_const)
end









f()



EOT

"./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT"
if ! ( diff "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "Output mismatched"
fi

"./$TOOL" "$INPUT" | "./$TOOL" > "$ACTUAL_OUTPUT"
if ! ( diff "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
   die "Output is not idempotent"
fi


# ................................................................
# Cleanup.
rm -f "$INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
exit 0
