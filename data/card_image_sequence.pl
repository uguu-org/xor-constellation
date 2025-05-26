#!/usr/bin/perl -w
# Generate a set of Makefile rules for compositing a random subset of
# title character images.
#
# The original intent to generate launcher cards where every other letter
# would blink at random intervals.  We ended up not using this idea because
# the flashing characters turned out a bit annoying.

use strict;
use constant SEQUENCE_LENGTH => 40;
use constant BIT_COUNT => 16;
use constant MAX_TOGGLE_BITS => 5;

# Title text placement within launcher cards.
#
# Title text is at (103,50) when shown on title screen, shifted down to
# (103,78) when centered.  Launch card is at (25,43), thus we need to shift
# by (103-25,78-43).
use constant SHIFT_X => 78;
use constant SHIFT_Y => 35;


# Use deterministic seed.
srand(1);

# Frame 0 has every bit set.
my @sequence = ((1 << BIT_COUNT) - 1);

# For each subsequent frame, clear some subset of bits to zero.
my %unique = ($sequence[0] => 1);
for(my $i = 1; $i < SEQUENCE_LENGTH; $i++)
{
   # Choose a subset of bits to toggle, with the constraint that the
   # selected bit must be set in the previous frame.
   my $previous = $sequence[$i - 1];
   my $bits;
   do
   {
      # Create a random permutation of 0..BIT_COUNT using Fisher-Yates shuffle.
      # This is used for selecting random bits to toggle.
      #
      # We could also just keep calling rand() until we find one that would
      # satisfy the constraints, but then we wouldn't know if we have already
      # tried every bit and none of them satisfied the constraint.
      my @choices = ();
      for(my $j = 0; $j < BIT_COUNT; $j++)
      {
         push @choices, $j;
      }
      for(my $j = BIT_COUNT - 1; $j > 0; $j--)
      {
         my $k = int(rand($j));
         my $tmp = $choices[$j];
         $choices[$j] = $choices[$k];
         $choices[$k] = $tmp;
      }

      my %select = ();
      foreach my $x (@choices)
      {
         my $x = int(rand(BIT_COUNT));

         # Retry if bit has already been selected.
         next if exists $select{$x};

         # Retry if neighboring bits has already been selected.
         next if exists $select{$x - 1};
         next if exists $select{$x + 1};

         # Retry if bit was turned off in the previous frame.
         next if ($previous & (1 << $x)) == 0;

         # Accept this bit.
         $select{$x} = 1;

         # Stop when we got enough bits.
         last if (scalar keys %select) >= MAX_TOGGLE_BITS;
      }

      # Toggle bits.
      $bits = $sequence[0];
      foreach my $x (keys %select)
      {
         $bits &= ~(1 << $x);
      }
   } while( exists $unique{$bits} );

   # Add to sequence.
   $unique{$bits} = 1;
   push @sequence, $bits;
}

# Generate summary.
printf '# %016b'."\n", $_ foreach @sequence;

# Generate Makefile rules.
for(my $i = 0; $i < SEQUENCE_LENGTH; $i++)
{
	my $inputs = "";
	for(my $bit = 0; $bit < BIT_COUNT; $bit++)
	{
		if( $sequence[$i] & (1 << $bit) )
		{
         $inputs .= " " if $inputs ne "";
			$inputs .= sprintf 't_title_char_%x.png', $bit;
		}
	}

   if( $i == 0 )
   {
      # Extra rules for frame 0: generate image with all characters, then
      # generate a striped version to serve as background for all other frames.
      print "t_all_chars.png: stack_bw.exe $inputs\n",
            "\t./stack_bw.exe $inputs > \$\@\n\n",
            "t_striped_card0.png: t_all_chars.png horizontal_stripes.exe\n",
            "\t./horizontal_stripes.exe < \$\< > \$\@\n\n",
            "t_card0.png: t_all_chars.png\n",
            "\tconvert -size 350x155 xc:'#ffffff'",
            " '(' \$\< -geometry +", SHIFT_X, "+", SHIFT_Y, " ')'",
            " -composite \$\@\n\n";
   }
   else
   {
      print "t_card$i.png: stack_bw.exe t_striped_card0.png $inputs",
            "\n",
            "\t./stack_bw.exe t_striped_card0.png $inputs ",
            "| convert -size 350x155 xc:'#ffffff'",
            " '(' png:- -geometry +", SHIFT_X, "+", SHIFT_Y, " ')'",
            " -composite \$\@\n\n";
   }
}
