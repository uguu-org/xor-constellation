#!/usr/bin/perl -w
# Inline integer constants.
#
# This is a dodgy script that replaces a certain subset of integer constant
# expressions with evaluated results.  The output allows a few variables to
# be eliminated with dubious performance implications.  It does not handle
# many things including but not limited to multi-line expressions and
# comments.  Use at your own peril.

use strict;
use POSIX;

# Table of (identifier, integer) pairs.
my %constants = ();

# Replace constant references with table values.
sub inline_constants($)
{
   my ($expr) = @_;

   my $head = "";
   my $tail = $expr;
   for(;;)
   {
      if( $tail =~ /^(\s*)([[:alpha:]]\w*)\b(.*)$/ )
      {
         # Found an identifier, try looking it up in the constant table.
         if( exists $constants{$2} )
         {
            # Inline this constant.
            $head .= $1 . $constants{$2};
         }
         else
         {
            # All other identifiers get passed on as-is.
            $head .= $1 . $2;
         }
         $tail = $3;
      }
      elsif( $tail =~ /^(\s*\S)(.*)$/ )
      {
         # Didn't find an identifier, consume one non-whitespace character
         # and move on.
         $head .= $1;
         $tail = $2;
      }
      else
      {
         # Everything that's left are whitespaces.
         last;
      }
   }
   return $head . $tail;
}

# Replace parts of the expression that can be evaluated at compile time,
# and return the updated expression.
sub rewrite_expr($);
sub rewrite_expr($)
{
   my ($expr) = @_;

   # Rewrite parenthesized expressions.
   for(my $i = index($expr, '('); $i >= 0; $i = index($expr, '(', $i))
   {
      my $j = $i + 1;
      my $nest = 1;
      for(; $j < length($expr); $j++)
      {
         if( substr($expr, $j, 1) eq ')' )
         {
            $nest--;
            if( $nest == 0 )
            {
               last;
            }
         }
         elsif( substr($expr, $j, 1) eq '(' )
         {
            $nest++;
         }
      }
      if( $nest != 0 )
      {
         # Unmatched parentheses.
         return $expr;
      }

      my $subexpr = rewrite_expr(substr($expr, $i + 1, $j - $i - 1));
      if( $subexpr =~ /^-?(?:0x[[:xdigit:]]+|\d+)$/ )
      {
         # Sub-expression evaluates to a single integer constant.  If
         # the open parenthesis is preceded by word character, this is
         # probably a function call, and we need to preserve the
         # parentheses.
         #
         # For everything else, we assume that these parentheses are
         # safe to be dropped.
         if( $i > 0 && substr($expr, $i - 1, 1) =~ /\w/ )
         {
            $expr = substr($expr, 0, $i) . "($subexpr)" . substr($expr, $j + 1);
            $i += length($subexpr) + 2;
         }
         else
         {
            $expr = substr($expr, 0, $i) . $subexpr . substr($expr, $j + 1);
            $i += length($subexpr);
         }
      }
      elsif( $subexpr eq "" )
      {
         # Sub-expression evaluates to an empty string, so this was a
         # function call.  We will preserve the parentheses and move on.
         $expr = substr($expr, 0, $i) . "()" . substr($expr, $j + 1);
         $i += 2;
      }
      else
      {
         # Sub-expression evaluates to something else, so we can't reduce
         # this expression any further.
         return $expr;
      }
   }

   # Rewrite multiply/divide/modulus operations.
   #
   # Note that only integer division ("//") is supported, floating point
   # division ("/") is explicitly ignored.
   while( $expr =~ /^(.*?)
                     (-?(?:0x[[:xdigit:]]+|\d+))\s*
                     (\*|\/\/|%)\s*
                     (-?(?:0x[[:xdigit:]]+|\d+))\s*
                     (.*)/x )
   {
      my ($head, $a, $op, $b, $tail) = ($1, $2, $3, $4, $5);
      if( $op eq "*" or $op eq "%" )
      {
         $expr = $head . eval("$a $op $b") . $tail;
      }
      else
      {
         # Divide, then truncate toward negative infinity.
         my $q = eval($a) / eval($b);
         $expr = $head . floor($q) . $tail;
      }
   }

   # Stop if the expression contains operators that we couldn't replace.
   if( $expr =~ /[\/*%]/ ) { return $expr; }

   # Rewrite add/subtract operations.
   while( $expr =~ /^(.*?)
                     (-?(?:0x[[:xdigit:]]+|\d+))\s*
                     (\+|-)\s*
                     (-?(?:0x[[:xdigit:]]+|\d+))\s*
                     (.*)/x )
   {
      my ($head, $a, $op, $b, $tail) = ($1, $2, $3, $4, $5);
      $expr = $head . eval("$a $op $b") . $tail;
   }

   # Rewrite shift operations.
   while( $expr =~ /^(.*?)
                     (-?(?:0x[[:xdigit:]]+|\d+))\s*
                     (<<|>>)\s*
                     (-?(?:0x[[:xdigit:]]+|\d+))\s*
                     (.*)/x )
   {
      my ($head, $a, $op, $b, $tail) = ($1, $2, $3, $4, $5);

      # Shifting by zero always results in no-op.
      $b = eval($b);
      if( $b == 0 )
      {
         $expr = $head . $a . $tail;
         next;
      }

      # Truncate to 32 bits before shifting.
      $a = eval($a);
      my $x = ($a & 0xffffffff);
      $x = $op eq ">>" ? $x >> $b : $x << $b;

      # Convert back to signed 32bit integer.
      $x = unpack "l", (pack "l", $x);
      $expr = $head . $x . $tail;
   }
   return $expr;
}


while( my $line = <> )
{
   chomp $line;

   # Replace existing constants on this line, so that constant definitions
   # that reference other constants will have those constants folded.
   $line = inline_constants($line);

   # Rewrite right side of a local variable or constant definition.
   #
   # Note that this is the only kind of expression that we would rewrite,
   # all other expressions are left untouched.  We support these variable
   # assignments because most of them end in a single line, and we have
   # verified the behavior for these with some care.
   #
   # We could try harder to fold constants in other places, we just didn't
   # want to.
   if( $line =~ /^(\s*local\s+\w+\s*<const>\s*=\s*)(.*?)$/ )
   {
      $line = $1 . rewrite_expr($2);
   }

   # After lines have been rewritten, if everything that's left is a constant
   # definition, we will add the constant to our constant table and drop the
   # definition line.  Otherwise we will just output the updated line.
   #
   # Note that we only replace constant definitions that are not indented.
   # The intent is to only support constants that are at file scope, and not
   # deal with any constants that are scoped to a function.  Not supporting
   # scoping rules means we don't need to maintain any other parsing state
   # (besides the table of constants).
   if( $line =~ /^local\s+(\w+)\s*<const>\s*=\s*
                  (-?(?:0x[[:xdigit:]]+|\d+))\s*$/x )
   {
      $constants{$1} = eval($2);
      print "\n";
   }
   else
   {
      print $line, "\n";
   }
}
