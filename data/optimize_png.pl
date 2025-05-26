#!/usr/bin/perl -w
# Read a PNG with alpha from command line argument or stdin, and write a
# stripped+optimized PNG to stdout.

use strict;
use File::Spec;
use File::Temp;

my $tmp = File::Temp->newdir();

# Write input PNG to disk.
my $input_png = join '', <ARGV>;
open my $infile, ">$tmp/in.png" or die $!;
print $infile $input_png;
close $infile;

# Split PNG to pixels and alpha and combine them back.  This causes
# all metadata to be dropped.
#
# This might be a bad idea if there is some critical info that we need.
# Usually the most important metadata lost here would be the color
# correction info, which we don't care about since we are only dealing
# with black and white images.
system "pngtopnm $tmp/in.png | ppmtoppm > $tmp/pixels.ppm";
system "pngtopnm -alpha $tmp/in.png > $tmp/alpha.ppm";
system "pnmtopng -compression 9 -alpha=$tmp/alpha.ppm $tmp/pixels.ppm > $tmp/combined.png";

# Drop STDERR before running pngcrush.  We do this because pngcrush is
# never completely silent despite "-s", and likes to print things like
# "versions are different between png.h and png.c" and "CPU time".  The
# former is probably cygwin's fault but the latter is not.  We don't
# need STDERR from here on anyways so we might as well drop those.
open STDERR, ">" . File::Spec->devnull() or die $!;

# Run pngcrush and write output bytes to stdout.  If pngcrush failed
# here, we wouldn't know what it complained about because we dropped
# STDERR, but we would notice the problem through other means.
system "pngcrush -s -brute $tmp/combined.png /dev/stdout";

# Temporary files are automatically deleted when $tmp goes out of scope.
