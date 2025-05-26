#!/usr/bin/perl -w
# Generate tables of integers containing at most some number of bits set.
#
# The goal of this game is to match the bits in the right positions so that
# we get all zeroes or ones.  The difficulty in doing this increases
# proportional to the number of bits that may be flipped at each step.  Thus
# we can adjust the difficulty of each game by limiting the maximum number
# of 1-bit that would be set.
#
# This tool generates tables of integers with varying upper bounds for the
# number of 1-bits, one table for each (bit width, difficulty) combination.
# Note that tiles with more than the specified number of bits may still
# appear, since they may be needed to complete a solution path.

use strict;

# Odds of getting an all-zero target.
#
# All-zero targets are basically free points since they don't flip any
# bits, and they provide extra flexibility in reaching other targets.
# Basically they are just very convenient to have, so we increase the
# probability of generating an all-zero target by padding the output
# tables with extra zeroes, such that an all-zero target appears with the
# odds of 1:ODDS_OF_ALL_ZEROES regardless of bit width and difficulty.
use constant ODDS_OF_ALL_ZEROES => 13;


# Difficulty thresholds for each bit width.
my %max_bits =
(
   4 => [1, 2, 3, 4],
   8 => [1, 2, 5, 8],
);

# Count number of bits set.
sub bit_count($)
{
   my ($x) = @_;
   $x = ($x & 0x55) + (($x >> 1) & 0x55);
   $x = ($x & 0x33) + (($x >> 2) & 0x33);
   $x = ($x & 0x0f) + (($x >> 4) & 0x0f);
   return $x;
}

print "BIT_TABLE =\n{\n";
my @size = ();
for(my $width = 4; $width <= 8; $width += 4)
{
   foreach my $bits (@{$max_bits{$width}})
   {
      print "\t-- $width bits, at most $bits bits set\n\t{\n";

      # Generate zero and all nonzero entries that satisfies the bit limit
      # criteria.
      my $count = 0;
      for(my $i = 0; $i < (1 << $width); $i++)
      {
         if( bit_count($i) <= $bits )
         {
            print "\t\t$i,\n";
            $count++;
         }
      }

      # Pad table with extra zeroes to increase the probability of
      # an all-zero target.
      my $zero_padding = int($count / (ODDS_OF_ALL_ZEROES - 1));
      for(my $i = 0; $i < $zero_padding; $i++)
      {
         print "\t\t0,\n";
         $count++;
      }

      push @size, $count;
      print "\t},\n";
   }
}
print "}\n",
      "BIT_TABLE_SIZE =\n{\n\t",
      (join ",\n\t", @size), "\n",
      "}\n"
