#!/usr/bin/perl -w
# Cleanup redundant style attributes.
#
# Usage:
#  ./cleanup_styles.pl input.svg > output.svg
#
# It seems that Inkscape would just attach attributes if you have the tool
# tab open, even if the attributes are redundant (e.g. apply stroke-dasharray
# when there is no stroke).  The intent might have been to preserve user
# specified values across certain edits, but they also greatly increases the
# SVG file size.  This script is used to reduce file sizes.

use strict;
use XML::LibXML;

# Container bitmasks.
use constant INSIDE_TEXT => 1;
use constant INSIDE_CLIP_PATH => 2;

# Map of style attributes to their defaults.
#
# The keys came from what's observed in our SVGs, so it's not exhaustive.
# The default values came from here:
# https://developer.mozilla.org/en-US/docs/Web/SVG
# https://developer.mozilla.org/en-US/docs/Web/CSS
#
# If we are aware of an attribute but don't want to replace it, it will be
# listed below but commented out.  In all cases, it's because the existing
# documentation does not list a clear default.
my %attribute_defaults =
(
   # "color" => undef,
   "color-interpolation-filters" => "linearRGB",
   "display" => "inline",
   "fill" => "remove",
   "fill-opacity" => "1",
   "fill-rule" => "nonzero",
   "filter" => "none",
   # "font-family" => undef,
   "font-size" => "medium",
   "font-stretch" => "normal",
   "font-style" => "normal",
   "font-variant" => "normal",
   "font-variant-caps" => "normal",
   "font-variant-east-asian" => "normal",
   "font-variant-ligatures" => "normal",
   "font-variant-numeric" => "normal",
   "font-variation-settings" => "normal",
   "font-weight" => "normal",
   "image-rendering" => "auto",
   "letter-spacing" => "normal",
   "line-height" => "normal",
   "marker-end" => "none",
   "marker-start" => "none",
   "mix-blend-mode" => "normal",
   "opacity" => "1",
   "overflow" => "visible",
   "paint-order" => "normal",
   "stop-color" => "black",
   "stop-opacity" => "1",
   "stroke" => "none",
   "stroke-dasharray" => "none",
   "stroke-dashoffset" => "none",
   "stroke-linecap" => "butt",
   "stroke-linejoin" => "miter",
   "stroke-opacity" => "1",
   "stroke-width" => "1px",
   # "text-align" => undef,
   # "text-anchor" => undef,
   "vector-effect" => "none",
   "word-spacing" => "normal",
);

# List of attributes that we want for clip paths.  Actually most of these
# can be dropped since they don't affect rendering, but they are useful
# for editing the clip path itself.
my %clip_path_attributes_whitelist =
(
   "display" => 1,
   "fill" => 1,
   "fill-opacity" => 1,
   "fill-rule" => 1,
   "opacity" => 1,
   "stroke" => 1,
   "stroke-width" => 1,

   # We should be able to drop stroke-linejoin, but sometimes it affect
   # how filtered objects are rendered in a way that's not pixel perfect.
   # These differences might have been mostly imperceptible in grayscale,
   # but when dithered, they do show up as pixel differences in a few
   # places that mattered.
   "stroke-linejoin" => 1,
);

# Advance line index until the indexed line contains the specified string.
# It's line_index because it's 0-based, as opposed to "line number" which is
# 1-based.  Returns the updated line index, or dies on error.
#
# This is a hack around the 65535 line number limitation in libxml2.  CPAN
# charitably summarized it as "a long and sad story", linking to a bug that
# I might summarize as an unhelpful stubborn developer versus the world.
# Anyways, line_number() is no good, which is probably why it's disabled
# by default.
#
# Since Inkscape never outputs two "style" attributes on the same line, and
# traversing the DOM in depth-first fashion basically processes the document
# in file order, we can fake our own line numbers by maintaining an index
# inside the list of lines, and occasionally advancing that index to keep it
# in sync with the tree traversal.  This is exactly what's implemented here.
sub advance_line_index($$$)
{
   my ($lines, $line_index, $text) = @_;

   while( $$line_index < scalar @$lines )
   {
      if( index($$lines[$$line_index], $text) >= 0 )
      {
         # Return the current line index, and also advance line_index to
         # point at the next line.  This is so that we don't scan the same
         # line twice.
         return $$line_index++;
      }
      ++$$line_index;
   }
   die "Parser out of sync with text $text\n";
}

# Check for presence of multiple style attributes on the same line, since
# that would break advance_line_index.
sub check_for_same_line_attributes($)
{
   my ($lines) = @_;

   foreach my $i (@$lines)
   {
      next unless $i =~ /\bstyle=".*".*\bstyle=".*"/;

      # Found multiple style attributes on the same line, try suggesting
      # some remediation steps.  The first thing we look for is xml:space,
      # which seem to have no good use anyways:
      # https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xml:space
      #
      # But Inkscape will insert xml:space occasionally, and files containing
      # this attribute will be badly formatted in a way that makes diffs
      # noisy.  User will need to manually remove all xml:space for Inkscape
      # to properly reformat the file.
      foreach (@$lines)
      {
         if( /xml:space="preserve"/ )
         {
            die <<EOT;
Input seems to be formatted in a condensed way that isn't supported
by this script.  Please try the following:

1. Delete all xml:space="preserve" attributes.
2. Open the file in Inkscape and save it again to reformat all elements.
EOT
         }
      }

      # There isn't any xml:space but the formatting is still bad.  Having
      # Inkscape rewrite the file usually does the trick.
      die <<EOT;
Input seems to be formatted in a condensed way that isn't supported
by this script.  Please try having Inkscape rewrite the file.
EOT
   }
}

# Check that an attribute exists and has some value other than "none".
#
# Note that this is not the same as checking whether a value is the same
# as default, since default fill value is "remove".
sub has_attribute($$)
{
   my ($attributes, $key) = @_;
   return (defined $$attributes{$key}) && $$attributes{$key} ne "none";
}

# Rebuild style string from current attribute values.
sub rewrite_style($$$$)
{
   my ($container, $current_style, $parent_attributes, $attributes) = @_;

   # Check for presence of fill/stroke/dashes.
   my $has_fill = has_attribute($attributes, "fill");
   my $has_stroke = has_attribute($attributes, "stroke");
   my $has_dash = $has_stroke && has_attribute($attributes, "stroke-dasharray");

   # Reset fill attributes to defaults if fill is "none".
   if( !$has_fill )
   {
      foreach my $k (keys %$attributes)
      {
         # Note the trailing dash, since we want to match attributes with
         # "fill-" prefix but not "fill" itself.
         if( $k =~ /^fill-/ )
         {
            $$attributes{$k} = $attribute_defaults{$k};
         }
      }
   }

   # Reset stroke attributes to defaults if stroke is "none".
   if( !$has_stroke )
   {
      foreach my $k (keys %$attributes)
      {
         if( $k =~ /^(?:stroke-|vector-effect)/ )
         {
            $$attributes{$k} = $attribute_defaults{$k};
         }
      }
   }
   elsif( !$has_dash )
   {
      # Reset just the stroke dash attributes.
      foreach my $k (keys %$attributes)
      {
         if( $k =~ /^stroke-dash/ )
         {
            $$attributes{$k} = $attribute_defaults{$k};
         }
      }
   }

   # Unconditionally drop certain inkscape-specific attributes.
   # -inkscape-stroke attributes are always unconditionally dropped.
   foreach my $k (keys %$attributes)
   {
      if( $k =~ /^(?:-inkscape-stroke|-inkscape-font-specification)/ )
      {
         $$attributes{$k} = $attribute_defaults{$k};
      }
   }

   # Drop paint-order if either stroke or fill is empty.
   if( !$has_fill || !$has_stroke )
   {
      $$attributes{"paint-order"} = $attribute_defaults{"paint-order"};
   }

   # Drop font related attributes if we are not inside a text node.
   if( ($container & INSIDE_TEXT) == 0 )
   {
      foreach my $k (keys %$attributes)
      {
         if( $k =~ /^(?:font-|letter-spacing|word-spacing|-inkscape-font)/ )
         {
            $$attributes{$k} = $attribute_defaults{$k};
         }
      }
   }

   # Drop extra attributes if we are inside a clip path.
   if( ($container & INSIDE_CLIP_PATH) != 0 )
   {
      foreach my $k (keys %$attributes)
      {
         unless( exists $clip_path_attributes_whitelist{$k} )
         {
            $$attributes{$k} = $attribute_defaults{$k};
         }
      }
   }

   # Go through the list of attributes in the original style text, and keep
   # only those attributes that differs from the default.
   #
   # We could have canonicalized the attributes by collecting the attributes
   # in sorted order, but we do it this way to preserve the order in the
   # original file.
   my @filtered_attributes = ();
   foreach my $s (split /;/, $current_style)
   {
      $s =~ /^\s*(\S[^:]*):\s*(\S.*?)\s*$/ or die;
      my $key = $1;
      my $value = $2;
      exists $$attributes{$key} or die;

      # If an attribute is undef, it's a signal that we always want to drop it.
      if( !defined $$attributes{$key} )
      {
         next;
      }

      # Drop attributes that matches SVG/CSS defaults, unless:
      # - the attribute is "display", or
      # - the attribute overrides some non-default value in parent.
      #
      # In theory, we should be able to drop all attributes that matches
      # the parent.  And since we started traversing the tree with root
      # set to attribute_defaults, we won't need any special handling for
      # default values.  In practice, Inkscape's attribute inheritance seems
      # a bit more subtle than we expected, and we would get different results
      # if we assume all attributes are inherited by all their children.
      if( defined $attribute_defaults{$key} &&
          $$attributes{$key} eq $attribute_defaults{$key} &&
          ($key eq "display" ||
           !defined $$parent_attributes{$key} ||
           $$parent_attributes{$key} eq $attribute_defaults{$key}) )
      {
         next;
      }

      push @filtered_attributes, "$key:$value";
   }
   return (join ";", @filtered_attributes);
}

# Recursively cleanup style attributes in child.
sub cleanup_element($$$$$);
sub cleanup_element($$$$$)
{
   my ($lines, $line_index, $parent_style, $container, $node) = @_;

   # Check if we have entered a text node.
   my $name = eval('$node->nodeName');
   if( defined $name )
   {
      if( $name eq "text" )
      {
         $container |= INSIDE_TEXT;
      }
      elsif( $name eq "clipPath" )
      {
         $container |= INSIDE_CLIP_PATH;
      }
   }

   # Get style attributes used by current node.
   my $style = eval('$node->{"style"}');
   unless( defined $style )
   {
      # No style definition in current node.  Keep going with its child nodes
      # while carrying the parent styles forward as is.
      foreach my $child ($node->childNodes())
      {
         cleanup_element(
            $lines, $line_index, $parent_style, $container, $child);
      }
      return;
   }

   # Style should not contain quotes?  Check here just in case.
   if( index($style, '"') >= 0 )
   {
      die "Found quoted style near line " . $node->line_number() . "\n";
   }

   # Find line index in the original file with the matching style line.
   # We modify the lines via textual replacements in the list of lines,
   # as opposed to modifying the style attribute in the dom and
   # reassembling the updated SVG.  Doing it this way preserves formatting
   # of the original file.
   my $i = advance_line_index($lines, $line_index, "style=\"$style\"");

   # Build combined style attributes.
   my %attributes = ();
   foreach my $k (keys %$parent_style)
   {
      $attributes{$k} = $$parent_style{$k};
   }
   foreach my $a (split /;/, $style)
   {
      unless( $a =~ /^\s*(\S[^:]*):\s*(\S.*?)\s*$/ )
      {
         die "Bad attribute $a near line " . ($i + 1) . "\n";
      }
      $attributes{$1} = $2;
   }

   # Rewrite style string.
   $$lines[$i] =~ /^(.*style=")([^"]*)(".*)$/s or die;
   $$lines[$i] = $1 .
                 rewrite_style($container, $2, $parent_style, \%attributes) .
                 $3;

   # Recursively clean up child nodes.
   foreach my $child ($node->childNodes())
   {
      cleanup_element($lines, $line_index, \%attributes, $container, $child);
   }
}

# Remove empty or redundant style/clip-path/nodetype attributes.
sub remove_redundant_attributes($$)
{
   my ($pattern, $lines) = @_;

   for(my $i = 0; $i < scalar @$lines; $i++)
   {
      if( $$lines[$i] =~ /^\s*$pattern\s*$/s )
      {
         $$lines[$i] = "";
      }
      elsif( $$lines[$i] =~ /^\s*$pattern\s*( \/>)\s*$/s ||
             $$lines[$i] =~ /^\s*$pattern\s*(\/>|>)\s*$/s )
      {
         my $close_bracket = $1;
         if( $$lines[$i - 1] =~ />\s*$/s )
         {
            print STDERR "Failed to remove empty attribute near line ", $i + 1,
                         "\n";
         }
         else
         {
            chomp $$lines[$i - 1];
            $$lines[$i - 1] .= "$close_bracket\n";
            $$lines[$i] = "";
         }
      }
      else
      {
         $$lines[$i] =~ s/^(.*?)\s*$pattern(.*)$/$1$2/s;
      }
   }
}

# Load all lines to a list.
my @lines = <>;
check_for_same_line_attributes(\@lines);

# Parse all lines as SVG.
my $dom = XML::LibXML->load_xml(string => (join "", @lines));
my $line_index = 0;

# Recursively cleanup elements, using all the default attribute values as
# current style.
cleanup_element(\@lines, \$line_index, \%attribute_defaults, 0, $dom);

# Cleanup leftover bits.
remove_redundant_attributes('style=""', \@lines);
remove_redundant_attributes('clip-path="none"', \@lines);
remove_redundant_attributes('sodipodi:nodetypes="c*"', \@lines);

# Output updated lines.
print foreach @lines;
