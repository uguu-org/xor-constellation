#!/usr/bin/perl -w
# Gather element count stats from XML file.

use strict;
use XML::LibXML::Reader;

if( $#ARGV < 0 )
{
   die "$0 {input.xml}\n";
}

my %element_count = ();
foreach my $f (@ARGV)
{
   my $reader = XML::LibXML::Reader->new(location => $f);
   while( $reader->read )
   {
      # Only count nodes that mark start of elements.  This skips over things
      # like comments (e.g. "<!-- -->") and also closing tags (e.g. "</svg>").
      if( $reader->nodeType == XML_READER_TYPE_ELEMENT )
      {
         $element_count{$reader->name}++;
      }
   }
}

my $total = 0;
foreach (sort keys %element_count)
{
   print "$_ $element_count{$_}\n";
   $total += $element_count{$_};
}
print "TOTAL $total\n";
