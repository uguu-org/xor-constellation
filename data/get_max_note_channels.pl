#!/usr/bin/perl -w
# Parse list of notes from NOTE_GROUPS table and output number of maximum
# channels need to play any group.

use strict;

my $max = 0;
while( my $line = <> )
{
   next unless $line =~ /^\s*\{([[:digit:], ]+)\},/;
   my $data = $1;
   my @notes = split /,/, $data;
   if( $max < scalar @notes )
   {
      $max = scalar @notes;
   }
}
print "MAX_NOTE_CHANNELS = $max\n";
