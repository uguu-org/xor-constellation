#!/usr/bin/perl -w
# Given lines containing 6 tuples, where each tuple is either an integer
# specifying a guitar fret position or "x", output a list of semitones
# from C2.

use strict;

my @offset =
(
   4,   # E2
   9,   # A2
   14,  # D3
   19,  # G3
   23,  # B3
   28   # E4
);

while( my $line = <> )
{
   # Preserve blank lines from original.
   if( $line =~ /^\s*$/s )
   {
      print "\n";
      next;
   }

   # Parse fret positions.
   next unless( $line =~ m/^\s*(x|\d+)[, ]+
                               (x|\d+)[, ]+
                               (x|\d+)[, ]+
                               (x|\d+)[, ]+
                               (x|\d+)[, ]+
                               (x|\d+)/x );
   my @s = ($1, $2, $3, $4, $5, $6);

   # Convert notes to semitones, and also record the last nonempty note.
   my $last = 0;
   for(my $i = 0; $i < 6; $i++)
   {
      if( $s[$i] ne "x" )
      {
         $s[$i] = $offset[$i] + $s[$i];
         $last = $i;
      }
   }

   # Output notes.
   print "\t{";
   for(my $i = 0; $i < 6; $i++)
   {
      if( $s[$i] eq "x" )
      {
         print "  ";
         print "  " if( $i < 5 );
      }
      else
      {
         if( $i < $last )
         {
            printf "%2d, ", $s[$i];
         }
         else
         {
            printf "%2d", $s[$i];
            print "  " if( $i < 5 );
         }
      }
   }
   print "},\n";
}
