#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "$0 {inline_constants.pl}"
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
-- No replacements.
no_op1 = 10
no_op2 = 20
no_op3 = no_op1 + no_op2
no_op4 = (unmatched
no_op5 = 30 / 40

-- Straighftforward constant replacements.
local const1 <const> = 10
const_replacement1 = const1
local const2 <const> = const1
const_replacement2 = const2
   local variable1 <const> = const2
variable2 = variable1

-- Remove parentheses.
local remove_parentheses1 <const> = (10) + rand()
local remove_parentheses2 <const> = ((20)) + rand()
local remove_parentheses3 <const> = (-30) + rand()
local remove_parentheses4 <const> = (40) + rand() + (50)
local no_emove_parentheses5 <const> = ((-x)) + rand()
local no_emove_parentheses6 <const> = rand(5)

-- Expressions with two terms.
local binary_expr1 <const> = 7 + 3
print(binary_expr1)
local binary_expr2 <const> = 30 - 10
print(binary_expr2)
local binary_expr3 <const> = -10 + 40
print(binary_expr3)
local binary_expr4 <const> = -15 - 25
print(binary_expr4)
local binary_expr5 <const> = 10 * 5
print(binary_expr5)
local binary_expr6 <const> = 120 // 2
print(binary_expr6)
local binary_expr7 <const> = 1 // 2
print(binary_expr7)
local binary_expr8 <const> = -1 // 2
print(binary_expr8)
local binary_expr9 <const> = 5 // -4
print(binary_expr9)
local binary_expr10 <const> = -10 // -3
print(binary_expr10)
local binary_expr11 <const> = 10 % 6
print(binary_expr11)

local shift_expr1 <const> = 1 << 3
print(shift_expr1)
local shift_expr2 <const> = 8 >> 3
print(shift_expr2)
local shift_expr3 <const> = -1 << 3
print(shift_expr3)
local shift_expr4 <const> = -1 >> 0
print(shift_expr4)
local shift_expr5 <const> = -1 >> 1
print(shift_expr5)

-- Expressions with more than two terms.
local operator_precedence1 <const> = 4 * 2 + 2
print(operator_precedence1)
local operator_precedence2 <const> = 4 + 8 * 2
print(operator_precedence2)
local operator_precedence3 <const> = (6 + 9) * 2
print(operator_precedence3)
local operator_precedence4 <const> = 80 * 1 // 2
print(operator_precedence4)
local operator_precedence5 <const> = 100 // 4 * 2
print(operator_precedence5)
local operator_precedence6 <const> = 5 + 25 << 1
print(operator_precedence6)
local operator_precedence7 <const> = 140 >> 2 - 1
print(operator_precedence7)
local operator_precedence8 <const> = 4 * 4 + 8 * 8
print(operator_precedence8)

-- Hexadecimal literals.
local hex1 <const> = 0xa
print(hex1)
local hex2 <const> = 0xf + 0x5
print(hex2)
local hex3 <const> = 0x20 - 0x2
print(hex3)
local hex4 <const> = (0x2 << 0x4) + 0x8
print(hex4)
local hex5 <const> = 0x5 * 2 * 0x5
print(hex5)
EOT

cat <<EOT > "$EXPECTED_OUTPUT"
-- No replacements.
no_op1 = 10
no_op2 = 20
no_op3 = no_op1 + no_op2
no_op4 = (unmatched
no_op5 = 30 / 40

-- Straighftforward constant replacements.

const_replacement1 = 10

const_replacement2 = 10
   local variable1 <const> = 10
variable2 = variable1

-- Remove parentheses.
local remove_parentheses1 <const> = 10 + rand()
local remove_parentheses2 <const> = 20 + rand()
local remove_parentheses3 <const> = -30 + rand()
local remove_parentheses4 <const> = 40 + rand() + 50
local no_emove_parentheses5 <const> = ((-x)) + rand()
local no_emove_parentheses6 <const> = rand(5)

-- Expressions with two terms.

print(10)

print(20)

print(30)

print(-40)

print(50)

print(60)

print(0)

print(-1)

print(-2)

print(3)

print(4)


print(8)

print(1)

print(-8)

print(-1)

print(2147483647)

-- Expressions with more than two terms.

print(10)

print(20)

print(30)

print(40)

print(50)

print(60)

print(70)

print(80)

-- Hexadecimal literals.

print(10)

print(20)

print(30)

print(40)

print(50)
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

