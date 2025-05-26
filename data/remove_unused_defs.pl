#!/usr/bin/perl -w
# Remove unused definitions from <defs> section of SVGs.
#
# This is used to further canonicalize output from select_layers.pl, such
# that definition changes on layers that are unrelated to the current
# selected layers are excluded from output.  This improves cache hit rate
# for svg_to_png.sh.

use strict;
use XML::LibXML;

# Load XML text from stdin or first argument.
my $text = join "", <ARGV>;

# Find definitions to remove.  Do this in multiple passes until there are
# no more definitions to remove.  Multiple passes are needed because it's
# common for gradients to reference other gradients in definitions, and we
# want to remove all gradients that became orphaned after their dependents
# got removed in an earlier pass.
#
# Note the extra "no_blanks=>1" option to strip whitespaces on load, which
# improves cache hit rate.  If we were to keep whitespaces, we will need
# extra work to delete the whitespaces that were attached to unused
# definitions.
my $dom = XML::LibXML->load_xml(string => $text, no_blanks => 1, huge => 1);

# Rebuild text from loaded DOM.  This is so that even if we don't have any
# definitions to remove, we would still output SVGs with whitespaces
# stripped.  This also makes the next loop run faster by reducing the
# amount of text that needed to be searched.
$text = $dom->toString();

for(;;)
{
   # Build index of all references.  These come in one of two flavors:
   # style="...:url(#id);..."
   # href="#id"
   #
   # After having built this index, we only need to look here to see if
   # a definition is used, as opposed to having to search the full text
   # later.  This makes the removal process run much faster.
   my %refs = ();
   foreach my $r ($text =~ /url\([']*#([^()]+)[']*\)/g)
   {
      $refs{$r} = 1;
   }
   foreach my $r ($text =~ /\bhref="#([^"]+)"/g)
   {
      $refs{$r} = 1;
   }

   my @unused_defs = ();
   foreach my $defs ($dom->getElementsByTagName("defs"))
   {
      foreach my $node ($defs->childNodes())
      {
         # Try to get element id attribute, skip on error.  Most common failure
         # mode is that $node is actually a XML::LibXML::Text as opposed to
         # XML::LibXML::Element, and trying to evaluate '$node->{"id"}' would
         # result in a "Not a HASH reference" error.
         my $id = eval('$node->{"id"}');
         next unless defined($id);

         unless( exists $refs{$id} )
         {
            push @unused_defs, $node;
         }
      }
   }
   if( (scalar @unused_defs) == 0 )
   {
      last;
   }

   # Remove definitions and references.
   foreach my $node (@unused_defs)
   {
      my $id = $node->{"id"};
      $node->parentNode->removeChild($node);
   }

   # Rebuild text with removed nodes.
   $text = $dom->toString();
}

# Output updated XML.
print $text;
