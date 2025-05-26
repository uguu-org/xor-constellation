#!/usr/bin/perl -w
# Strip comments, assertions, and unreferenced locals from Lua file,
# preserving line numbers.
#
# This is because we write the unittests alongside the code that are needed
# for production, and we don't want to include those in the final build.  This
# script is effectively a garbage collector for lines and locals that are only
# reachable via assert().
#
# This script works by finding functions and checking if there are any
# references outside the function definition.  Because all references in one
# function might be inside another function that was removed earlier, we need
# multiple passes to clean up everything.  Alternatively, we can invent a
# notation to mark regions of code that should be removed by this script,
# which would allow all cleanup to be done in just one pass, but it's more
# robust to have a script figure out what to remove automatically, so that's
# what we are doing here.
#
# There are other things we can do such as inlining constants, which would
# offer a tiny bit of speedup (about 50 nanoseconds per lookup), but here we
# are on the slippery slope to implementing an optimizing preprocessor.  I am
# sure that would be a fun project, but maybe we will save that one for later.

use strict;

# Load all lines to memory, since we need to go through multiple passes.
my @lines = <>;

# First pass to strip all comments and assertions.
my $block_comment = 0;
foreach my $line (@lines)
{
   chomp $line;
   if( $block_comment )
   {
      if( $line =~ /^--\]\]/ )
      {
         $block_comment = 0;
      }
      $line = "";
   }
   else
   {
      # Strip block comments.
      if( $line =~ /^--\[\[/ )
      {
         $block_comment = 1;
         $line = "";
         next;
      }

      # Strip single line comments.
      $line =~ s/^(
                     (?:
                        '(?:\\.|[^'\\])*' |
                        "(?:\\.|[^"\\])*" |
                        [^'"]
                     )*?
                  )
                  (\s*--.*)/$1/x;

      # Strip assertions.
      $line =~ s/^\s*assert\(.*\).*//;

      # Replace line with empty string if there is only whitespaces left.
      if( $line =~ /^\s*$/ )
      {
         $line = "";
      }
   }
}

# Get all local function/variable/constant names, and store the line ranges
# where they are defined.
my %locals = ();
for(my $i = 0; $i < (scalar @lines); $i++)
{
   if( $lines[$i] =~ /^local function (\w+)\b/ )
   {
      # Local function.
      my $name = $1;
      my $start = $i;
      my $end = undef;
      for(my $j = $i + 1; $j < (scalar @lines); $j++)
      {
         if( $lines[$j] =~ /^end\b/ )
         {
            $end = $j;
            last;
         }
      }
      unless( defined $end )
      {
         die "$start: could not find the end of function $name\n";
      }
      $i = $end;
      $locals{$name} = [$start, $end];
   }
   elsif( $lines[$i] =~ /^local (\w+)\b.*=/ )
   {
      # Local variable or constant.  Unlike functions, these don't have
      # an "end" marker to tell us where the definition ends, so we use
      # a heuristic where if the "=" appears in the middle of the line,
      # we assume all the definition fits on a single line.  Otherwise,
      # we don't try to remove the identifier at all.
      my $name = $1;
      if( $lines[$i] =~ /=.*\S/ )
      {
         $locals{$name} = [$i, $i];
      }
   }
}

# Strip unused locals in multiple passes until there is nothing to remove.
for(;;)
{
   # For each function or variable, scan through all lines outside the
   # definition to see if the identifier is referenced.
   my @remove_locals = ();
   foreach my $f (keys %locals)
   {
      my ($start, $end) = @{$locals{$f}};
      my $pattern = qr/\b$f\b/;
      my $unused = 1;

      # Scan lines before the function or variable definition.
      for(my $i = 0; $i < $start; $i++)
      {
         if( $lines[$i] =~ $pattern )
         {
            $unused = 0;
            last;
         }
      }
      if( $unused )
      {
         # Scan lines after the function or variable definition.
         for(my $i = $end + 1; $i < (scalar @lines); $i++)
         {
            if( $lines[$i] =~ $pattern )
            {
               $unused = 0;
               last;
            }
         }
      }
      if( $unused )
      {
         # No references found, delete this function or variable.
         for(my $i = $start; $i <= $end; $i++)
         {
            $lines[$i] = "";
         }
         push @remove_locals, $f;
      }
   }
   if( (scalar @remove_locals) == 0 )
   {
      # Didn't remove anything, so we are done.
      last;
   }

   foreach my $f (@remove_locals)
   {
      delete $locals{$f};
   }
}

# Output updated lines.
print "$_\n" foreach @lines;
