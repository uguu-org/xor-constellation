#!/usr/bin/perl -w
# Generate table of sample rate multipliers for raising pitch by some number
# of semitones.

use constant STEPS => 48;

my @note = ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B");

print "RATE_MULTIPLIER =\n{\n";
for(my $i = 0; $i < STEPS; $i++)
{
   my $label = $note[$i % 12] . (int($i / 12) + 3);

   print "\t", 2 ** (($i - 12) / 12.0), ",\t-- $label\n";
}
print "}\n";
