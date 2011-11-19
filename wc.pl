#!/usr/bin/perl -w
#
# Exercise:
#
# Given a test file containing lines of words such as 
# (abc, abb, abd, abb, etc), write a script that prints, 
# in order of frequency, how many times each word appears in the file.
#
# Basic errror handling and a simple --help instructions should be included

#
# Sample input:
# 
# abc abb abd abb etc
#
use strict;
use Getopt::Long;

# Print the usage information
sub usage
{
	print ("Usage: $0 < word_list_file\n");
	exit;
}

# Look for the --help on the command line, print the usage
my $HELP = "";
GetOptions ('help' => \$HELP);
if ( $HELP )
{
	usage ();
}

# If <STDIN> is not re-directed, print the usage
my $STDIN_REDIRECTED = ! -t STDIN;      # Is STDIN redirected from a file?
if ( ! $STDIN_REDIRECTED )
{
	usage ();
}

# Delcare a hash to hold the word count
my %entry;

# Read from <STDIN>
while (<>)
{
	# For each "word" split by using the \w character class
	while ( /(\w['\w-]*)/g  ) 
	{
		# lowercase all the words so "Of" and "of" match
		$entry{lc $1}++;
	}
}

# Print a sorted list by frequency of the words found in the sample
for my $key ( sort { $entry{$a} <=> $entry{$b}} keys %entry)
{

	print ( "$entry{$key}\t$key\n");
}


