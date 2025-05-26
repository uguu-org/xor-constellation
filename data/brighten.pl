#!/usr/bin/perl -w
# Brighten colors for some subset of layers.

use strict;
use XML::LibXML;

# Brighten a color specified as a string of 6 hexadecimal digits.
sub brighten($)
{
   my ($color) = @_;
   my $r = hex(substr($color, 0, 2));
   my $g = hex(substr($color, 2, 2));
   my $b = hex(substr($color, 4, 2));
   return sprintf '%02x%02x%02x',
                  int(($r + 0xff) / 2),
                  int(($g + 0xff) / 2),
                  int(($b + 0xff) / 2);
}

# Brighten colors in a node and all child nodes.
sub recursive_apply($);
sub recursive_apply($)
{
   my ($node) = @_;

   # Rewrite colors within style attribute.
   my $style = eval('$node->{"style"}');
   if( defined($style) )
   {
      my $head = "";
      my $tail = $style;
      while( $tail =~ /^(.*?(?:fill|stroke):#)([[:xdigit:]]{6})(.*)$/ )
      {
         $head = $1 . brighten($2);
         $tail = $3;
      }
      $node->{"style"} = $head . $tail;
   }

   # Recursively apply to child.
   foreach my $child ($node->childNodes())
   {
      recursive_apply($child);
   }
}


if( $#ARGV < 0 )
{
   die "$0 {layer pattern}\n";
}
my $layer_pattern = shift @ARGV;
$layer_pattern = qr/$layer_pattern/;

# Load XML from stdin or last argument.
my $dom = XML::LibXML->load_xml(huge => 1, string => join "", <ARGV>);

# Iterate through all group nodes.
foreach my $group ($dom->getElementsByTagName("g"))
{
   if( defined $group->{"inkscape:groupmode"} &&
       defined $group->{"inkscape:label"} &&
       $group->{"inkscape:groupmode"} eq "layer" &&
       $group->{"inkscape:label"} =~ $layer_pattern )
   {
      recursive_apply($group);
   }
}

# Output updated XML.
print $dom->toString(), "\n";
