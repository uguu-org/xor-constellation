#!/usr/bin/perl -w
# Check symbol references in Lua files, and output symbols that seem suspect.
#
# This is a simplistic regex-based tool with known false positives, and it's
# not at the level for fully automated usage.  The reason why we have this
# dodgy script instead of just going with an existing full-featured linter
# is because this one has fewer dependencies, and is more tolerant of syntax
# variations introduced by Playdate's variant of Lua.  Basically it's good
# enough for our use case, but not good enough for anyone else.

use strict;

# Hierarchical stack of symbol tables.  First entry contains global symbols,
# second entry contains file-local symbols, subsequent entries are symbols
# of various nesting depth.
my @symbols = ({}, {});

# Global nesting stack to keep track of the parent table name in "table={}".
my @context = ();

# Add keywords to global symbols.
${$symbols[0]}{$_} = "<keyword>" foreach qw{
   and
   break
   const
   do
   else
   elseif
   end
   false
   for
   function
   goto
   if
   in
   local
   nil
   not
   or
   repeat
   return
   then
   true
   until
   while

   import
};

# Add identifiers from various libraries.
${$symbols[0]}{$_} = "<core>" foreach qw{
   assert
   pairs
   print
   tonumber
   type

   coroutine.create
   coroutine.resume
   coroutine.yield

   math.abs
   math.atan2
   math.cos
   math.floor
   math.max
   math.min
   math.pi
   math.random
   math.randomseed
   math.sin
   math.sqrt

   string.format
   string.find

   table.create
   table.insert
   table.remove
   table.unpack

   gfx.clear
   gfx.drawCircleAtPoint
   gfx.drawLine
   gfx.drawRect
   gfx.drawText
   gfx.drawTextAligned
   gfx.drawTriangle
   gfx.fillRect
   gfx.fillTriangle
   gfx.getDisplayImage
   gfx.getDrawOffset
   gfx.getTextSize
   gfx.image.kDitherTypeBayer8x8
   gfx.image.kDitherTypeFloydSteinberg
   gfx.image.new
   gfx.imagetable.new
   gfx.kColorBlack
   gfx.kColorClear
   gfx.kColorWhite
   gfx.kDrawModeCopy
   gfx.kDrawModeFillBlack
   gfx.kDrawModeFillWhite
   gfx.kDrawModeNXOR
   gfx.kImageFlippedX
   gfx.kImageFlippedY
   gfx.kImageUnflipped
   gfx.popContext
   gfx.pushContext
   gfx.setBackgroundColor
   gfx.setColor
   gfx.setDitherPattern
   gfx.setDrawOffset
   gfx.setImageDrawMode
   gfx.setLineWidth
   gfx.setPattern
   gfx.sprite.new
   gfx.sprite.update
   gfx.tilemap.new
   kTextAlignment.right
   playdate.accelerometerIsRunning
   playdate.buttonIsPressed
   playdate.buttonJustPressed
   playdate.buttonJustReleased
   playdate.datastore.read
   playdate.datastore.write
   playdate.drawFPS
   playdate.geometry.affineTransform.new
   playdate.getCrankPosition
   playdate.getElapsedTime
   playdate.getSecondsSinceEpoch
   playdate.getSystemMenu
   playdate.graphics
   playdate.isCrankDocked
   playdate.isSimulator
   playdate.kButtonA
   playdate.kButtonB
   playdate.kButtonDown
   playdate.kButtonLeft
   playdate.kButtonRight
   playdate.kButtonUp
   playdate.metadata.buildNumber
   playdate.metadata.name
   playdate.metadata.version
   playdate.readAccelerometer
   playdate.setCrankSoundsDisabled
   playdate.setMenuImage
   playdate.sound.channel.new
   playdate.sound.envelope.new
   playdate.sound.sampleplayer.new
   playdate.startAccelerometer
   playdate.stopAccelerometer
   playdate.timer.keyRepeatTimer
   playdate.timer.new
   playdate.timer.updateTimers
};

# Add some member functions.  This is a kludge in that we really should
# keep track of variable types to see if the member functions attached to
# them are valid, but doing that requires weaving through an entire type
# system.  If we really wanted that level of accuracy, we would have been
# using a real Lua interpretor instead.
${$symbols[0]}{$_} = "<member_functions>" foreach qw{
   :add
   :addMenuItem
   :addOptionsMenuItem
   :addSource
   :addSprite
   :blurredImage
   :copy
   :draw
   :drawCentered
   :drawFaded
   :drawIgnoringOffset
   :drawImage
   :drawRotated
   :drawSampled
   :fadedImage
   :getImage
   :getLength
   :getPosition
   :getSize
   :getTileAtPosition
   :getValue
   :moveTo
   :play
   :remove
   :rotatedImage
   :setCenter
   :setImage
   :setImageTable
   :setScale
   :setSize
   :setSustain
   :setTileAtPosition
   :setTilemap
   :setTiles
   :setValue
   :setVisible
   :setVolumeMod
   :setZIndex
   :stop
   :transformedImage
   :trigger
};


# Common patterns.
my $match_identifier_prefix = qr/^\s*([_[:alpha:]][.\w]*)/;
my $match_function =
   qr/^\s*(local\s+)?function\s+([_[:alpha:]][.\w]*)\(([^()]*)\)\s*$/;


# Lookup a singe symbol reference in @symbols and return where it's defined.
# Returns undef if symbol is not found.
sub lookup_symbol($)
{
   my ($identifier) = @_;

   for(my $i = $#symbols; $i >= 0; $i--)
   {
      if( exists ${$symbols[$i]}{$identifier} )
      {
         return ${$symbols[$i]}{$identifier};
      }
   }
   return undef;
}

# Add a symbol to symbol table if it's not already there.
# Always returns zero.
sub add_symbol($$$$)
{
   my ($filename, $line_number, $identifier, $local) = @_;

   my $existing_symbol = lookup_symbol($identifier);
   if( defined($existing_symbol) )
   {
      if( $local )
      {
         # If we wanted to check for locals shadowing globals, this would
         # be the place to do it:
         #
         #   print "$filename:$line_number: $identifier shadows ",
         #         "earlier definition at $existing_symbol\n";
         #   return 1;
         #
         # But because we are running with a dodgy parser, these kind of
         # warnings are almost entirely false positives.
         return 0;
      }
   }
   else
   {
      my $scope = $local ? $#symbols : 0;
      my $location = "$filename:$line_number";
      ${$symbols[$scope]}{$identifier} = $location;

      # Also add global symbol qualified with parent context.
      #
      # The fact that we are adding at as a global instead of inside the scope
      # that defined the original table is not accurate, but works for our
      # use case.
      if( (scalar @context) && $context[$#context] ne "" )
      {
         ${$symbols[0]}{$context[$#context] . "." . $identifier} = $location;
      }
   }
   return 0;
}

# Check identifier in symbol table.  If it's not found, output a warning
# and add it as a local, then return nonzero status.  This is so that
# we will get warnings only on first use.
#
# Returns zero if symbol already exists.
sub check_and_add($$$)
{
   my ($filename, $line_number, $identifier) = @_;

   if( defined(lookup_symbol($identifier)) )
   {
      return 0;
   }
   print "$filename:$line_number: $identifier\n";
   add_symbol($filename, $line_number, $identifier, 1);
   return 1;
}

# Add symbols for function parameters.  Returns nonzero if there were any
# shadowing problems.  @symbols is updated on return.
sub parse_parameters($$$)
{
   my ($filename, $line_number, $parameters) = @_;

   my $errors = 0;
   foreach my $a (split /[, ]/, $parameters)
   {
      if( $a =~ $match_identifier_prefix )
      {
         $errors += add_symbol($filename, $line_number, $a, 1);
      }
   }
   return $errors;
}

# Handle definition on a single line.  Returns nonzero if there were any
# shadowing problems.  @symbols is updated on return.
sub parse_definitions($$$)
{
   my ($filename, $line_number, $line) = @_;

   # Try matching the various definitions we know about.  Note that order
   # is sensitive.
   #
   # 1. local function f(params)
   #    function f(params)
   # 2. for var =
   # 3. for var1, var2 in
   # 4. if
   #    while
   #    do
   # 5. local var
   #    local var =
   # 6. var =
   # 7. ... function()

   my $errors = 0;
   if( $line =~ $match_function )
   {
      # Function definition.
      my $local = defined($1);
      my $identifier = $2;
      my $parameters = $3;
      $errors += add_symbol($filename, $line_number, $identifier, $local);

      # Create new scope for this function.
      push @symbols, {};

      # Add symbols for all function parameters.
      $errors += parse_parameters($filename, $line_number, $parameters);
   }
   elsif( $line =~ /^\s*for\s*(\w+)\s*=/ )
   {
      # For-loops (single variable).
      my $identifier = $1;

      # Create new scope for this loop.
      push @symbols, {};
      $errors += add_symbol($filename, $line_number, $identifier, 1);
   }
   elsif( $line =~ /^\s*for\s*(\w+),\s*(\w+)\s*in/ )
   {
      # For-loops (pairs).
      my $first = $1;
      my $second = $2;

      # Create new scope for this loop.
      push @symbols, {};
      $errors += add_symbol($filename, $line_number, $first, 1);
      $errors += add_symbol($filename, $line_number, $second, 1);
   }
   elsif( $line =~ /^\s*(?:if|while|do)\b/ )
   {
      # Various scope blocks.
      #
      # Add new scope, unless input is a single-line if-block.
      if( $line !~ /^\s*if\b.*\bend\b/ )
      {
         push @symbols, {};
      }
   }
   elsif( $line =~ /^\s*local\s+([^=]*)/ )
   {
      # Local variables.
      my $identifier_list = $1;
      while( $identifier_list =~ s/^([^,]*),(.*)$/$2/ )
      {
         my $prefix = $1;
         if( $prefix =~ $match_identifier_prefix )
         {
            $errors += add_symbol($filename, $line_number, $1, 1);
         }
      }
      if( $identifier_list =~ $match_identifier_prefix )
      {
         $errors += add_symbol($filename, $line_number, $1, 1);
      }

      if( $line =~ /\bfunction\(([^()]*)\)\s*$/ )
      {
         # Function definition.
         push @symbols, {};
         $errors += parse_parameters($filename, $line_number, $1);
      }
   }
   elsif( $line =~ /^\s*([^=]+)\s*=/ )
   {
      # Assignment expression.
      my $identifier_list = $1;
      while( $identifier_list =~ s/^([^,]*),(.*)$/$2/ )
      {
         my $prefix = $1;
         if( $prefix =~ $match_identifier_prefix )
         {
            $errors += add_symbol($filename, $line_number, $1, scalar @context);
         }
      }
      if( $identifier_list =~ $match_identifier_prefix )
      {
         $errors += add_symbol($filename, $line_number, $1, scalar @context);
      }

      if( $line =~ /\bfunction\(([^()]*)\)\s*$/ )
      {
         # Function definition.
         push @symbols, {};
         $errors += parse_parameters($filename, $line_number, $1);
      }
   }
   elsif( $line =~ /\bfunction\(([^()]*)\)\s*$/ )
   {
      # Function definition as an argument to some function call.
      push @symbols, {};
      $errors += parse_parameters($filename, $line_number, $1);
   }

   return $errors;
}

# Process a subset of a line without braces, returning number of errors.
sub process_sub_line($$$)
{
   my ($filename, $line_number, $line) = @_;

   my $errors = parse_definitions($filename, $line_number, $line);
   my $text = $line;
   while( $text =~ s/^\s*(\S.*)$/$1/ )
   {
      # Skip numbers.
      if( $text =~ s/^\d\w+(.*)$/$1/ )
      {
         next;
      }

      # Check identifier references.
      if( $text =~ s/^((?::)?[_[:alpha:]][.\w]*)(.*)$/$2/ )
      {
         my $identifier = $1;
         $errors += check_and_add($filename, $line_number, $identifier);
         next;
      }

      # Drop leading character and try again.
      $text = substr($text, 1);
   }

   # Pop symbol stack and the end of each block.
   if( $line =~ /^\s*end\b/ )
   {
      if( scalar @context )
      {
         print "$filename:$line_number: unclosed {\n";
         $errors++;
         return $errors;
      }
      if( (scalar @symbols) <= 2 )
      {
         print "$filename:$line_number: unmatched end\n";
         $errors++;
         return $errors;
      }
      pop @symbols;
   }

   # Reset symbol stack across conditional branches.
   if( $line =~ /^\s*(?:else|elseif)\b/ )
   {
      if( scalar @context )
      {
         print "$filename:$line_number: unclosed {\n";
         $errors++;
      }
      pop @symbols;
      push @symbols, {};
   }
   return $errors;
}

# Process a full line, taking nesting level into account.  Returns number
# of errors.
sub process_line($$$)
{
   my ($filename, $line_number, $line) = @_;

   if( scalar @context )
   {
      my $errors = 0;
      foreach my $sub_line (split /,/, $line)
      {
         $errors += process_sub_line($filename, $line_number, $sub_line);
      }
      return $errors;
   }
   return process_sub_line($filename, $line_number, $line);
}

# Extra checks that happen at the end of each file.  Returns number of errors.
sub eof_checks($$$)
{
   my ($filename, $line_number, $goto) = @_;

   if( (scalar @context) > 0 )
   {
      print "$filename:$line_number: expected \"}\"\n";
      return 1;
   }
   if( (scalar @symbols) > 2 )
   {
      print "$filename:$line_number: expected \"end\"\n";
      return 1;
   }

   my $errors = 0;
   if( scalar keys %$goto )
   {
      foreach my $label (sort keys %$goto)
      {
         foreach my $statement (@{$$goto{$label}})
         {
            print $statement, "\n";
            $errors++;
         }
      }
   }
   return $errors;
}

# Iterate through all input files.  Returns number of errors.
sub process_files()
{
   my $block_comment = 0;   # Set to nonzero if we are inside block comments.
   my $current_file = "";   # Current file name.
   my $current_line = 0;    # Current line number.
   my $errors = 0;          # Number of errors found.
   my %goto = ();           # Unresolved gotos.
   my $previous_line = "";  # Previous processed line.
   while( my $line = <> )
   {
      # Reset line number and file-level symbol table when we move on to
      # a new file.
      if( $current_file ne $ARGV )
      {
         $errors += eof_checks($current_file, $current_line, \%goto);
         pop @symbols;
         push @symbols, {};

         $current_file = $ARGV;
         $current_line = 0;
      }
      $current_line++;

      if( $block_comment )
      {
         # Skip block comments until closing "--]]".
         if( $line =~ /^--\]\]/ )
         {
            $block_comment = 0;
            $previous_line = "";
         }
         next;
      }

      # Check for start of block comments.
      if( $line =~ /^--\[\[/ )
      {
         $block_comment = 1;
         next;
      }

      # Strip single line comments.
      chomp $line;
      $line =~ s/^(
                     (?:
                        '(?:\\.|[^'\\])*' |
                        "(?:\\.|[^"\\])*" |
                        [^'"]
                     )*?
                  )
                  (\s*--.*)/$1/x;

      # Strip quoted strings.
      $line =~ s/"(?:\\.|[^"\\])*"//g;
      $line =~ s/'(?:\\.|[^'\\])*'//g;

      # Strip goto references.
      if( $line =~ s/^(.*)\bgoto\s+(\w+)(.*)$/$1 $3/ )
      {
         my $label = $2;
         unless (exists $goto{$label})
         {
            $goto{$label} = [];
         }
         push @{$goto{$label}}, "$current_file:$current_line: $label";
      }

      # Resolve goto labels.
      if( $line =~ s/^(.*)::(\w+)::(.*)$/$1 $3/ )
      {
         my $label = $2;
         delete $goto{$label};
      }

      # Rewrite all references of the form "table[index].member" to "table".
      #
      # This script can't deal with those because it requires knowing the
      # type of "table[index]", the most we can check is that table exists.
      $line =~ s/([_[:alpha:]][.\w]*)(?:\[[^\[\]]*\])+\.[.\w]+/$1/g;

      # Split line at {} boundaries and process each piece separately.
      while( $line =~ /[{}]/ )
      {
         if( $line =~ s/^([^{}]*)\{(.*)$/$2/ )
         {
            my $prefix = $1;
            $errors += process_line($current_file, $current_line, $prefix);
            if( $prefix =~ /\b([_[:alpha:]][.\w]*)\s=\s*$/ )
            {
               push @context, $1;
            }
            else
            {
               if( $previous_line =~ /\b([_[:alpha:]][.\w]*)\s=\s*$/ )
               {
                  push @context, $1;
               }
               else
               {
                  push @context, "";
               }
            }
            push @symbols, {};
         }
         elsif( $line =~ s/^([^{}]*)\}(.*)$/$2/ )
         {
            if( (scalar @context) <= 0 )
            {
               print "$current_file:$current_line: unexpected \"}\"\n";
               $errors++;
               return $errors;
            }
            $errors += process_line($current_file, $current_line, $1);
            pop @symbols;
            pop @context;
         }
      }

      # Process what's left of the line.
      $errors += process_line($current_file, $current_line, $line);

      $previous_line = $line;
   }

   $errors += eof_checks($current_file, $current_line, \%goto);
   return $errors;
}


if( process_files() )
{
   exit 1;
}
exit 0;
