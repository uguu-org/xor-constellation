#!/usr/bin/perl -w

use strict;
use XML::LibXML;

use constant PI => 3.14159265358979323846264338327950288419716939937510;

# Output position.
use constant OUTPUT_LAYER => "world - rectangles";
use constant OUTPUT_X => 0;
use constant OUTPUT_Y => 832;
use constant X_SPACING => 128;
use constant Y_SPACING => 96;

# Size settings.
use constant X_SIZE => 96;
use constant Y_SIZE => 64;
use constant VARIATION_COUNT => 8;
use constant FRAME_COUNT => 16;


# Serial number for generating unique IDs.
my $serial_number = 0;

# Generate unique IDs for each rectangle.
sub generate_id()
{
   ++$serial_number;
   return "generated_rectangle_$serial_number";
}

# Find layer where elements are to be added.
sub find_layer_by_name($$)
{
   my ($dom, $name) = @_;

   foreach my $group ($dom->getElementsByTagName("g"))
   {
      if( defined($group->{"inkscape:label"}) &&
          $group->{"inkscape:label"} eq $name )
      {
         return $group;
      }
   }
   die "Layer not found: $name\n";
}

# Add a set of fading rectangles.
sub add_rectangles($$$)
{
   my ($node, $sx, $sy) = @_;

   my @param = ();
   for(my $i = 0; $i < 10; $i++)
   {
      # Arrange rectangles in an elliptical fashion.
      my $a = $i * PI * 2 / 10.0;
      my $cx = X_SIZE * 0.2 * cos($a);
      my $cy = Y_SIZE * 0.2 * sin($a);

      # Generate rectangles with random sizes, but all with the same
      # aspect ratio.
      my $width = (rand(0.35) + 0.2) * X_SIZE;
      my $height = $width * Y_SIZE / X_SIZE;

      # Check that rectangle is within bounds.
      $cx - $width >= -X_SIZE or die;
      $cx + $width <= X_SIZE or die;
      $cy - $height >= -Y_SIZE or die;
      $cy + $height <= Y_SIZE or die;

      my $initial_opacity = rand(0.1) + 0.9;
      my $opacity_delta = rand(0.3);

      $cx += X_SPACING / 2 + $sx;
      $cy += Y_SPACING / 2 + $sy;
      push @param,
           [$cx, $cy, $width, $height, $initial_opacity, $opacity_delta];
   }
   for(my $frame = 0; $frame < FRAME_COUNT; $frame++)
   {
      foreach my $i (@param)
      {
         my @p = @$i;
         my $cx = $p[0] + $frame * X_SPACING;
         my $cy = $p[1];

         my $width = $p[2] * (1.0 - $frame / FRAME_COUNT);
         my $height = $p[3] * (1.0 - $frame / FRAME_COUNT);

         my $opacity = $p[4] - $p[5] * $frame;
         $opacity = $opacity > 0 ? $opacity : 0;

         my $r = XML::LibXML::Element->new("rect");
         $r->{"id"} = generate_id();
         $r->{"x"} = $cx - $width / 2;
         $r->{"y"} = $cy - $height / 2;
         $r->{"width"} = $width;
         $r->{"height"} = $height;
         $r->{"style"} = "fill:#ffffff;fill-opacity:$opacity";
         $node->addChild($r);
      }
   }
}


# Use fixed random seed for deterministic output.
srand(1);

# Load input.
unless( $#ARGV == 0 )
{
   die "$0 {input.svg} > {output.svg}\n";
}

my $dom = XML::LibXML->load_xml(location => $ARGV[0]);
my $output = find_layer_by_name($dom, OUTPUT_LAYER);

# Add rectangles.
for(my $y = 0; $y < VARIATION_COUNT; $y++)
{
   add_rectangles($output, OUTPUT_X, OUTPUT_Y + $y * Y_SPACING);
}

# Dump updated SVG to stdout.
print $dom->toString;
