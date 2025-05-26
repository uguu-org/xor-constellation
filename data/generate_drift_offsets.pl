#!/usr/bin/perl -w

use strict;
use constant DRIFT_FRAME_COUNT => 64;
use constant RADIUS => 5;
use constant ASPECT_RATIO => 32.0 / 24.0;
use constant PI => 3.14159265358979323846264338327950288419716939937510;

# Round away from zero.
sub round($);
sub round($)
{
   my ($v) = @_;
   return $v < 0 ? -round(-$v) : int($v + 0.5);
}


my $drift_offset_count = 0;
print "DRIFT_OFFSET =\n{\n";

# The outer loop here generates different size variations for each
# motion type.  This seems wasteful because we could have implemented
# the multiplier at run time, but we would get smoother motions if all
# the rounding operations are baked in.
for(my $size = 1; $size <= 3; $size++)
{
   # Drifts along a single axis.  Note that we only need to cover half
   # of the angle range, since two drifts that differs from each other
   # at 180 degrees will be indistinguishable once the phase is randomized.
   for(my $angle = 0; $angle < 180; $angle += 30)
   {
      my $a = ($angle + 90) * PI / 180.0;
      print "\t{\n";
      for(my $f = 0; $f < DRIFT_FRAME_COUNT; $f++)
      {
         my $r = RADIUS * sin($f * 2.0 * PI / DRIFT_FRAME_COUNT) / $size;
         my $x = $r * cos($a);
         my $y = $r * sin($a) / ASPECT_RATIO;
         print "\t\t{", round($x), ", ", round($y), "},\n";
      }
      print "\t},\n";
      $drift_offset_count++;
   }

   # Circular drifts.
   for(my $direction = -1; $direction <= 1; $direction += 2)
   {
      print "\t{\n";
      for(my $f = 0; $f < DRIFT_FRAME_COUNT; $f++)
      {
         my $a = $direction * $f * 2.0 * PI / DRIFT_FRAME_COUNT;
         my $r = RADIUS / $size;
         my $x = $r * cos($a);
         my $y = $r * sin($a) / ASPECT_RATIO;
         print "\t\t{", round($x), ", ", round($y), "},\n";
      }
      print "\t},\n";
      $drift_offset_count++;
   }
}

print "}\n",
      "DRIFT_OFFSET_COUNT = $drift_offset_count\n",
      "DRIFT_FRAME_COUNT = ", DRIFT_FRAME_COUNT, "\n";
