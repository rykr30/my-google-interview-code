#!/usr/bin/perl -w
use strict;

#
# Given a test file containing lines of words such as 
# (abc, abb, abd, abb, etc), write a script that prints, 
# in order of frequency, how many times each word appears in the file.
#

my %entry;

my $nonWords = 0;

# Read from <STDIN>
while (<>)
{
	# For each "word" split by mormal whitespace
	for my $word (split)
	{
		# Only count words that match the \w character class
		# This will also match words like abc$%$$%$$, which really isn't a word
		if ( $word =~ /\w/g )
		{
			# Strip out all non-alphanumeric characters (i.e. abc@#$@#$ becomes abc)

			# See if the word has any punctuation
			if ( $word =~ /[^\w\s-]/ )
			{
				# This may not be considered a word
			}
		
			# Strip comma's	
			$word =~ s/,$//;

			# Count up this word
			$entry{$word}++;
		}
		else
		{
			# This looks like a "non word" to me
			$nonWords++;
		}
	}
}


# Print a sorted list by frequency of the words found in the sample
for my $key ( sort { $entry{$a} <=> $entry{$b}} keys %entry)
{

	print ( "$entry{$key}\t$key\n");
}

print ( "\nAlso found $nonWords \"non words\".\n");

