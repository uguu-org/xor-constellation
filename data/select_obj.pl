#!/usr/bin/perl -w
# Usage:
#
#  perl select_obj.svg {layer} {id} < {input.svg} > {output.svg}
#
# Read {input.svg} and drop all objects within {layer} that does not have {id}.
#
# This is useful for splitting individual objects in a layer into separate
# independent SVGs.  We can also achieve the same using just select_layers.pl,
# but that requires moving each object to separate layers, so having this
# script makes the operation more convenient.

use strict;
use XML::LibXML;


# Read settings from command line.
if( $#ARGV < 1 )
{
   die "$0 {layer} {id.png} < {input.svg} > {output.svg}\n";
}
my $layer = shift @ARGV;
my $id = shift @ARGV;

# Load XML from stdin or last argument.
my $dom = XML::LibXML->load_xml(huge => 1, string => (join "", <ARGV>));

# Iterate through all group nodes.
foreach my $group ($dom->getElementsByTagName("g"))
{
   if( defined $group->{"inkscape:groupmode"} &&
       defined $group->{"inkscape:label"} &&
       $group->{"inkscape:groupmode"} eq "layer" )
   {
      if( $group->{"inkscape:label"} ne $layer )
      {
         # Found a layer that doesn't match the expected name.
         # This layer will be kept as is.
         next;
      }

      # Found the expected layer, now iterate over all child nodes and
      # find ones that didn't have the expected ID.
      my @delete_nodes = ();
      foreach my $child ($group->childNodes())
      {
         my $label = eval('$child->{"inkscape:label"}');
         unless( defined $label && $label eq $id )
         {
            push @delete_nodes, $child;
         }
      }

      # Delete nonmatching child nodes.
      foreach my $node (@delete_nodes)
      {
         $node->parentNode->removeChild($node);
      }
   }
}

# Output updated XML.
print $dom->toString(), "\n";
