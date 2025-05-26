#!/usr/bin/perl -w
# Usage:
#
#  perl select_layer.svg {pattern} {output.png} {input.svg} > {output.svg}
#
# Read input.svg, drop all layers that do not match pattern, set export
# filename to output.png and write the updated SVG to stdout.
#
# Note that this drops layers without regard to cross references.  For
# example, if Inkscape's "spray" tool is used in clone mode, and the
# original object is outside the selected layers, the <use> elements will
# silently fail to resolve.  To avoid that problem, either only make
# duplicates, or only make clones from objects in the same layer.
#
# That said, some cross references will survive just fine because the
# original live inside the <defs> section.  These include all gradients,
# clip paths, and patterns.

use strict;
use XML::LibXML;


# Read settings from command line.
if( $#ARGV < 1 )
{
   die "$0 {pattern} {output.png} {input.svg}\n";
}
my $pattern = shift @ARGV;
my $layer_regex = qr/$pattern/;
my $export_filename = shift @ARGV;

# Load XML from stdin or last argument.
my $dom = XML::LibXML->load_xml(huge => 1, string => (join "", <ARGV>));

# Iterate through all group nodes.
foreach my $group ($dom->getElementsByTagName("g"))
{
   if( defined $group->{"inkscape:groupmode"} &&
       defined $group->{"inkscape:label"} &&
       $group->{"inkscape:groupmode"} eq "layer" )
   {
      if( $group->{"inkscape:label"} =~ $layer_regex )
      {
         # Found a matching layer.  If it's currently invisible, force it
         # to be visible.
         if( defined $group->{"style"} )
         {
            $group->{"style"} =~ s/display:none/display:inline/;
            $group->{"style"} =~ s/opacity:0\.\d+/opacity:1/;
         }

         # Lock the layer if it wasn't locked already.  This is to
         # canonicalize output SVG with respect to locking changes, which
         # improves cache hit rate for svg_to_png.sh
         $group->{"sodipodi:insensitive"} = "true";
      }
      else
      {
         # Delete layers that don't match the expected pattern.
         $group->parentNode->removeChild($group);
      }
   }
}

# Update export filename.
foreach my $svg ($dom->getElementsByTagName("svg"))
{
   $svg->{"inkscape:export-filename"} = $export_filename;
}

# Delete view setting.  These have a tendency to gain unexpected variations
# but don't affect the generated output.  Deleting the view setting here
# improves cache hit rate with svg_to_png.sh
foreach my $view ($dom->getElementsByTagName("sodipodi:namedview"))
{
   $view->parentNode->removeChild($view);
}

# Output updated XML.
print $dom->toString(), "\n";
