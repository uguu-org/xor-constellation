#!/usr/bin/perl -w
# Look at the list of PNGs in input directory starting with 1.png, and
# replace any files that are identical to an earlier image in the sequence
# with references in animation.txt.
#
# perl dedup_images.pl launcher/card-highlighted
# perl dedup_images.pl launcher/icon-highlighted

use strict;

unless( $#ARGV == 0 )
{
   die "$0 {image_directory}\n";
}

my $image_dir = $ARGV[0];
$image_dir =~ s/\/*$//;

# Mapping from image contents to image index.
my %unique = ();

# List of image indices.
my @sequence = ();

# Try each image in sequence, stop when there are no more images.
for(my $i = 1;; $i++)
{
   my $filename = "$image_dir/$i.png";
   open my $infile, "< $filename" or last;
   my $data = join '', <$infile>;
   close $infile;

   if( exists $unique{$data} )
   {
      push @sequence, $unique{$data};
      unlink $filename or die $!;
   }
   else
   {
      push @sequence, $i;
      $unique{$data} = $i;
   }
}

# Write animation.txt.
unless( scalar @sequence )
{
   die "Did not match any images in $image_dir\n";
}
open my $outfile, "> $image_dir/animation.txt" or die $!;
print $outfile "frames = ", (join ", ", @sequence), "\n";
close $outfile;
