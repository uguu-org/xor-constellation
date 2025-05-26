#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {check_ref.pl}"
   exit 1
fi
TOOL=$1

set -euo pipefail
INPUT=$(mktemp)
SECOND_INPUT=$(mktemp)
EXPECTED_OUTPUT=$(mktemp)
ACTUAL_OUTPUT=$(mktemp)

function die
{
   echo "$1"
   rm -f "$INPUT" "$SECOND_INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
   exit 1
}

function check_success
{
   label="$1"

   if ! ( "./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT" ); then
      cat "$ACTUAL_OUTPUT"
      die "$label: unexpected failure"
   fi
   if [[ -s "$ACTUAL_OUTPUT" ]]; then
      cat "$ACTUAL_OUTPUT"
      die "$label: expected empty output, got something else"
   fi
}

function check_multi_input_success
{
   label="$1"

   if ! ( "./$TOOL" "$INPUT" "$SECOND_INPUT" > "$ACTUAL_OUTPUT" ); then
      cat "$ACTUAL_OUTPUT"
      die "$label: unexpected failure"
   fi
   if [[ -s "$ACTUAL_OUTPUT" ]]; then
      cat "$ACTUAL_OUTPUT"
      die "$label: expected empty output, got something else"
   fi
}

function check_failure
{
   label="$1"

   if ( "./$TOOL" "$INPUT" > "$ACTUAL_OUTPUT" ); then
      cat "$ACTUAL_OUTPUT"
      die "$label: unexpected success"
   fi
   if ! ( diff "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
      die "$label: output mismatched"
   fi
}

function check_multi_input_failure
{
   label="$1"

   if ( "./$TOOL" "$INPUT" "$SECOND_INPUT" > "$ACTUAL_OUTPUT" ); then
      cat "$ACTUAL_OUTPUT"
      die "$label: unexpected success"
   fi
   if ! ( diff "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" ); then
      die "$label: output mismatched"
   fi
}


# ................................................................
# Test handling of empty input and comments.

truncate --size=0 "$INPUT"
truncate --size=0 "$EXPECTED_OUTPUT"
check_success "$LINENO: empty"

cat <<EOT > "$INPUT"
--[[
comment1
--]]

-- comment2

-- function comment3()
-- end

"string1"
"\"string2" --comment5
EOT
check_success "$LINENO: comments"

# ................................................................
# Test parse errors related to nesting stack.

cat <<EOT > "$INPUT"
local function f()
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:1: expected "end"
EOT
check_failure "$LINENO: unclosed function"

cat <<EOT > "$INPUT"
if true then
else
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:2: expected "end"
EOT
check_failure "$LINENO: unclosed conditional"

cat <<EOT > "$INPUT"
a =
{
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:2: expected "}"
EOT
check_failure "$LINENO: unclosed brackets"

# ................................................................
# Test global definitions.

cat <<EOT > "$INPUT"
hoge = 0
function piyo()
end
print(hoge)
print(piyo)
EOT
check_success "$LINENO: global (success)"

cat <<EOT > "$INPUT"
defined1 = 1
function defined2()
end
print(undefined)
print(defined1)
print(defined2)
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:4: undefined
EOT
check_failure "$LINENO: global (failure)"

# ................................................................
# Test local references.

cat <<EOT > "$INPUT"
defined1 = undefined1  -- line 1: undefined reference
function f1(defined2)
   print(defined2)
   print(undefined2)  -- line 4: undefined reference
end
local function f2(defined3, defined4)
   print(defined3, undefined3)  -- line 7: undefined reference
   print(undefined4, defined4)  -- line 8: undefined reference
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:1: undefined1
$INPUT:4: undefined2
$INPUT:7: undefined3
$INPUT:8: undefined4
EOT
check_failure "$LINENO: undefined references"

# ................................................................
# Test local variables.

cat <<EOT > "$INPUT"
function f1()
   local var
end
function f2()
   print(var)  -- line 5: undefined reference
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:5: var
EOT
check_failure "$LINENO: local variable"

cat <<EOT > "$INPUT"
for i = 1, 2 do
   print(i)
end
print(i)  -- line 4: undefined reference
t = {}
for j, k in pairs(t) do
   print(j, k)
end
print(j, k)  -- line 9: undefined reference
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:4: i
$INPUT:9: j
$INPUT:9: k
EOT
check_failure "$LINENO: loop variables"

cat <<EOT > "$INPUT"
function f1(same_parameter)
end
function f2(same_parameter)  -- no error
end
function f3()
   local var = same_parameter  -- line 6: undefined reference
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:6: same_parameter
EOT
check_failure "$LINENO: function parameter"

cat <<EOT > "$INPUT"
a = {x = 3, y = 4}
b = {x = 5, y = 6}
c =
{
   x = 7,
   y = 8,
}
print(a.x)
print(a.y)
print(b.x)
print(b.y)
print(c.x)
print(c.y)
print(x)  -- line 14: undefined reference
print(y)  -- line 15: undefined reference
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:14: x
$INPUT:15: y
EOT
check_failure "$LINENO: dictionary"

cat <<EOT > "$INPUT"
local defined1, defined2 = 1, 2
local defined3 <const>, defined4 <const> = 3, 4
defined5, defined6 = 1, 2
print(defined1)
print(defined2)
print(defined3)
print(defined4)
print(defined5)
print(defined6)
EOT
truncate --size=0 "$EXPECTED_OUTPUT"
check_success "$LINENO: multiple assignment"

# ................................................................
# Test local functions.

cat <<EOT > "$INPUT"
f1 = function()
   local local_var1
end
function f2()
   print(local_var1)  -- line 5: undefined reference
   local local_var2 = function(param)
      local local_var3
      print(param)
   end
   print(local_var3)  -- line 10: undefined reference
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:5: local_var1
$INPUT:10: local_var3
EOT
check_failure "$LINENO: local function"

# ................................................................
# Verify that each undefined reference gets at most one warning per function.

cat <<EOT > "$INPUT"
local function f1()
   print(undefined)  -- line 2: undefined reference
   print(undefined)
end
local function f2()
   print(undefined)  -- line 6: undefined reference
   print(undefined)
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:2: undefined
$INPUT:6: undefined
EOT
check_failure "$LINENO: duplicate warnings"

# ................................................................
# Test conditionals.

cat <<EOT > "$INPUT"
if true then
   local defined1
   local defined2
elseif
   local defined1  -- no shadowing
   print(defined2)  -- line 6: undefined reference
   local defined3
   local defined4
else
   local defined1  -- no shadowing
   local defined3  -- no shadowing
   print(defined4)  -- line 12: undefined reference
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:6: defined2
$INPUT:12: defined4
EOT
check_failure "$LINENO: conditional"

# ................................................................
# Test goto labels.

cat <<EOT > "$INPUT"
local function f()
   for x = 1, 2 do
      goto next_x
      for y = 3, 4 do
         goto next_y
         print("skipped")
         ::next_y::
      end
      ::next_x::
   end
end
EOT
truncate --size=0 "$EXPECTED_OUTPUT"
check_success "$LINENO: goto (success)"

cat <<EOT > "$INPUT"
local function f()
   goto considered_harmful  -- line 2: undefined label
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:2: considered_harmful
EOT
check_failure "$LINENO: goto (failure)"

cat <<EOT > "$INPUT"
local function f()
   if true then goto success end
   if true then goto fail end  -- line 3: undefined label
   goto success
   goto fail  -- line 5: undefined label
   ::success::
end
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:3: fail
$INPUT:5: fail
EOT
check_failure "$LINENO: goto (multiple)"

# ................................................................
# Test definitions across multiple files.

cat <<EOT > "$INPUT"
print(undefined1)
EOT
cat <<EOT > "$SECOND_INPUT"
print(undefined2)
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:1: undefined1
$SECOND_INPUT:1: undefined2
EOT
check_multi_input_failure "$LINENO: simple multifile"

cat <<EOT > "$INPUT"
local function local_f()
end
function global.f()
end
EOT
cat <<EOT > "$SECOND_INPUT"
global.f()
EOT
truncate --size=0 "$EXPECTED_OUTPUT"
check_multi_input_success "$LINENO: multifile export (success)"

cat <<EOT > "$SECOND_INPUT"
local_f()  -- line 1: undefined reference
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$SECOND_INPUT:1: local_f
EOT
check_multi_input_failure "$LINENO: multifile export (failure)"

# ................................................................
# Test hack to ignore table member references.

cat <<EOT > "$INPUT"
t = {}
print(t[1].ignored)
print(t[2][3].ignored)
print(t[4][5][6].ignored)
print(undefined[1].ignored)  -- line 5: undefined table reference
EOT
cat <<EOT > "$EXPECTED_OUTPUT"
$INPUT:5: undefined
EOT
check_failure "$LINENO: table member"

# ................................................................
# Cleanup.
rm -f "$INPUT" "$SECOND_INPUT" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"
exit 0
