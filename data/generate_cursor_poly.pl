#!/usr/bin/perl -w
# Generate cursor polygon coordinates for each rotation angle.

use strict;
use constant WIDTH => 9;
use constant HEIGHT => 9;
use constant RADIUS => 36;
use constant ASPECT_RATIO => 32.0 / 24.0;
use constant PI => 3.14159265358979323846264338327950288419716939937510;

# Round away from zero.
sub round($);
sub round($)
{
   my ($v) = @_;
   return $v < 0 ? -round(-$v) : int($v + 0.5);
}


print "CURSOR_POLY =\n{\n";
for(my $i = 0; $i < 360; $i++)
{
   my $a = ($i - 90) * PI / 180.0;
   my $dx = cos($a);
   my $dy = sin($a);
   my $base_x = RADIUS * $dx;
   my $base_y = RADIUS * $dy;

   my $tip_x = $base_x + HEIGHT * $dx;
   my $tip_y = $base_y + HEIGHT * $dy;
   my $r_x = $base_x + WIDTH * 0.5 * $dy;
   my $r_y = $base_y - WIDTH * 0.5 * $dx;
   my $l_x = $base_x - WIDTH * 0.5 * $dy;
   my $l_y = $base_y + WIDTH * 0.5 * $dx;

   $tip_y /= ASPECT_RATIO;
   $r_y /= ASPECT_RATIO;
   $l_y /= ASPECT_RATIO;
   print "\t[$i] = {", round($tip_x), ", ", round($tip_y),
         ", ", round($r_x), ", ", round($r_y),
         ", ", round($l_x), ", ", round($l_y), "},\n";
}
print "}\n";
