#!/usr/bin/perl -w
# Generate dot graph from Makefile.
#
# This is not a generalized Makefile parser.  Supported syntax:
#
#   # comment
#
#   variable = value
#   variable ?= value
#
#   single_target: dependencies
#   (tab) actions
#
# No conditionals, suffix rules, etc.  It's very basic, but it's good enough
# for our Makefile.

use strict;
use Digest::MD5 qw(md5);

# Convert HSL in the range of [0,6),[0,1],[0,1] to RGB [0,255],[0,255],[0,255]
sub hsl_to_rgb($$$)
{
   my ($h, $s, $l) = @_;

   my $c = (1 - abs(2 * $l - 1)) * $s;
   my $x = $c * (1 - abs($h - 2 * int($h / 2) - 1));

   my ($r, $g, $b) = (0, 0, 0);
   if( $h < 1 )    { $r = $c; $g = $x; }
   elsif( $h < 2 ) { $r = $x; $g = $c; }
   elsif( $h < 3 ) { $g = $c; $b = $x; }
   elsif( $h < 4 ) { $g = $x; $b = $c; }
   elsif( $h < 5 ) { $r = $x; $b = $c; }
   else            { $r = $c; $b = $x; }

   my $m = $l - $c / 2;
   $r = int(($r + $m) * 255);
   $g = int(($g + $m) * 255);
   $b = int(($b + $m) * 255);
   return $r, $g, $b;
}

# Generate a random color by hashing a string.
#
# This is used to assign colors such that all targets and outgoing edges
# from the same target would get the same color.  This makes the edges
# easier to follow.
#
# Hashing is used, as opposed to simply assigning random colors or
# consecutive colors from a fixed palette.  This is so that the same target
# will always get assigned the same color across different invocations of
# this script.
sub generate_color($)
{
   my ($text) = @_;

   # Using MD5 as the hash function, hashing to HSL color space.
   my @byte = unpack 'C*', md5($text);
   my $h = $byte[0] / 256.0 * 6;
   my $s = $byte[1] / 255.0 * 0.6 + 0.4;
   my $l = $byte[2] / 255.0 * 0.55 + 0.25;
   my ($r, $g, $b) = hsl_to_rgb($h, $s, $l);

   return sprintf '#%02x%02x%02x', $r, $g, $b;
}

# Remove excessive leading/trailing/inner whitespaces from string.
sub remove_excessive_space($)
{
   my ($s) = @_;
   $s =~ s/^\s*(\S.*)$/$1/;
   $s =~ s/^(.*\S)\s*$/$1/;
   my @parts = split /\s+/, $s;
   return join " ", @parts;
}

# Escape quotes inside a string.
sub escape($)
{
   my ($t) = @_;

   $t =~ s/\\/\\\\/gs;
   $t =~ s/\n/\\n/gs;
   $t =~ s/"/\\"/gs;
   return $t;
}

# Assign numerical index to each target.
sub assign_index($$)
{
   my ($target, $index) = @_;

   unless( exists $$index{$target} )
   {
      $$index{$target} = scalar keys %$index;
   }
}

# Load build graph from file.
sub load($$$$)
{
   my ($filename, $index, $dependency, $actions) = @_;

   # Mapping from variable name to variable value.
   my %dictionary = ();

   # Build rule variables.
   my $current_target = undef;
   my $first_input = undef;
   my $all_inputs = undef;

   # Process input line by line.
   open my $infile, "< $filename" or die "Can not read $filename: $!\n";
   while( my $line = <$infile> )
   {
      # Drop comments.
      next if $line =~ /^#/;

      # Join line continuations.
      chomp $line;
      while( $line =~ s/^(.*)\\\s*$/$1/ )
      {
         my $continuation = <$infile>;
         last if not $continuation;
         $line .= $continuation;
         chomp $line;
      }

      # Handle variable substitutions.
      #
      # A proper Makefile parser would not expand variables inside quoted
      # strings, but we don't bother with any quote handling here.
      my $expanded_prefix = "";
      while( $line =~ /^(.*?)\$\(([^()]+)\)(.*)$/ )
      {
         my ($head, $variable, $tail) = ($1, $2, $3);
         unless( exists $dictionary{$variable} )
         {
            # Silently pass through undefined variables as is.
            # This is to support predefined variables such as $(MAKE).
            $dictionary{$variable} = "\$($variable)";
         }
         $expanded_prefix .= $head . $dictionary{$variable};
         $line = $tail;
      }
      $line = $expanded_prefix . $line;

      if( defined($current_target) )
      {
         $line =~ s/\$\@/$current_target/g;
      }
      if( defined($first_input) )
      {
         $line =~ s/\$</$first_input/g;

         # We support "$+" here because that's how this script actually
         # expands "$^", i.e. duplicates are kept as-is.
         #
         # We don't have any duplicate dependencies in our build rules, so
         # $^ and $+ have identical expansion for our makefiles.
         $line =~ s/\$\^/$all_inputs/g;
         $line =~ s/\$\+/$all_inputs/g;
      }

      if( $line =~ /^(\S+)\s*(?:=|\?=)\s*(\S.*)$/ )
      {
         # Variable definition.
         my $key = $1;
         my $value = remove_excessive_space($2);
         $dictionary{$key} = $value;
      }
      elsif( $line =~ /^(\S+)\s*:(.*)$/ )
      {
         # Rule definition.
         $current_target = $1;
         my $current_dependencies = remove_excessive_space($2);

         # Assign indices to targets and dependencies.
         $first_input = undef;
         assign_index($current_target, $index);
         foreach my $d (split /\s+/, $current_dependencies)
         {
            assign_index($d, $index);
            $$dependency{$current_target}{$d}++;
            if( defined($first_input) )
            {
               $all_inputs .= " $d";
            }
            else
            {
               $all_inputs = $first_input = $d;
            }
         }
      }
      elsif( $line =~ /^\t(.*)$/ )
      {
         # Build actions.
         if( defined($current_target) )
         {
            if( exists($$actions{$current_target}) )
            {
               $$actions{$current_target} .= "\n" . $1;
            }
            else
            {
               $$actions{$current_target} = $1;
            }
         }
      }
      else
      {
         # Some other line.  Either a blank line separating the rules, or some
         # make syntax that we don't support (such as conditionals).
         $current_target = undef;
         $first_input = undef;
         $all_inputs = undef;
      }
   }
}

# Generate graph for selected targets to stdout.
sub generate_graph($$$$)
{
   my ($index, $dependency, $actions, $targets) = @_;

   my %selected_targets = ();
   $selected_targets{$_} = 1 foreach @$targets;

   # Output header.
   #
   # Note the rankdir=RL bit, which allows reading the graph from left
   # to right in a way that roughly matches reading the original makefile
   # from top to bottom.
   print "digraph G {\n",
         "\tnode [shape=box,style=filled]\n",
         "\trankdir = RL\n",
         "\tsplines = ortho\n",
         "\ttooltip = \"",
         escape(join "\n", map {"Build target = $_"} @$targets), "\"\n";

   # Run depth-first traversal over the build graph in two passes,
   # outputting all the node names in the first pass and all the edges
   # in the second pass.
   for(my $pass = 0; $pass < 2; $pass++)
   {
      my @visit_stack = (@$targets);
      my %visited = ();
      while( scalar @visit_stack )
      {
         my $t = pop @visit_stack;
         next if exists $visited{$t};
         $visited{$t} = 1;
         if( $pass == 0 )
         {
            my $tooltip;
            if( exists $$actions{$t} )
            {
               $tooltip = escape($$actions{$t});
            }
            else
            {
               $tooltip = escape("$t\n(no actions)");
            }
            print "\tn$$index{$t} [label=\"$t\",",
                  (exists $selected_targets{$t} ? "penwidth=3," : ""),
                  "tooltip=\"$tooltip\",",
                  "fillcolor=white,",
                  "color=\"", generate_color($t), "\"]\n";
         }

         foreach my $d (sort {$$index{$a} <=> $$index{$b}}
                        keys %{$$dependency{$t}})
         {
            if( $pass == 1 )
            {
               # Draw edge from dependency to target.
               print "\tn$$index{$d} -> n$$index{$t}",
                     " [color=\"", generate_color($d),
                     "\",edgetooltip=\"", escape($t), " : ", escape($d),
                     "\"]\n";
            }
            push @visit_stack, $d;
         }
      }
   }

   # Output footer.
   print "}\n";
}


if( $#ARGV < 0 )
{
   die "$0 {Makefile} [target...]\n";
}

# Mapping from target name to when it first appeared in the input.
my %index = ();

# (target, (dependency, count))
my %dependency = ();

# (target, build actions)
my %actions = ();

load($ARGV[0], \%index, \%dependency, \%actions);

# Select which build targets to graph.
my @build_targets = ();
if( $#ARGV > 0 )
{
   # Set build targets from command line.
   shift @ARGV;
   foreach my $a (@ARGV)
   {
      unless( exists $index{$a} )
      {
         die "No rule to make target $a\n";
      }
      push @build_targets, $a;
   }
}
else
{
   # Set build target from first build rule.
   foreach my $a (sort {$index{$a} <=> $index{$b}} keys %index)
   {
      push @build_targets, $a;
      last;
   }
}

generate_graph(\%index, \%dependency, \%actions, \@build_targets);
