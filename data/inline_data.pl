#!/usr/bin/perl -w
# Usage:
#
# ./inline_data.pl {data.lua} {main.lua} > {output.lua}
#
# Replace the "import data" line in main.lua with contents of data.lua,
# and also make all variable declarations in data.lua local.  Motivation
# for doing this is to make the imported data variables invisible.

use strict;

unless( $#ARGV >= 0 )
{
   die "$0 {data.lua} {main.lua} > {output.lua}\n";
}
my $data_file = shift @ARGV;

# Load imported data lines.
my $data;
open my $infile, "< $data_file" or die $!;
while( my $line = <$infile> )
{
   $line =~ s/^(\w+)\s*=(.*)/local $1 <const> =$2/;
   $data .= $line;
}
close $infile;

# Generate expected import line.
my $import_line = $data_file;
$import_line =~ s/\.lua$//;
$import_line =~ s/^.*\/(\S+)$/$1/;
$import_line = "import \"$import_line\"";

# Copy main lines.
while( my $line = <> )
{
   if( substr($line, 0, length($import_line)) eq $import_line )
   {
      print $data;
   }
   else
   {
      print $line;
   }
}
