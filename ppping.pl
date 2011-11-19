#!/usr/bin/perl -w
#
# Write a script running in an endless loop that pings an IP 
# (specified on the command line) periodically. If the IP goes 
# down n times in a row send one email message (to an address 
# specified on the command line) that it's down (n is specified 
# on the command line).
#
# Once it's available again n times in a row send an email 
# that it's back up. When a specific signal is sent to the 
# script it sends and email saying that it is shutting down and 
# then exits.
#
# Basic errror handling and a simple --help instructions should be included.
#
# command line: ipaddress failure_threshold email
#
use strict;
use Getopt::Long;

# Print the usage information
sub usage
{
	print ( "Usage: $0 ipaddress failure_count emailaddress\n\n" );
	exit;
}

# Look for the --help on the command line, print the usage
my $HELP = "";
GetOptions ('help' => \$HELP);
if ( $HELP )
{
	usage ();
}

#
# Intercept Ctrl-C and run imDead
#
$SIG{INT} = \&imDead;

use Data::Validate::IP qw(is_ipv4);   # For validating the IP address
use Mail::RFC822::Address qw(valid);  # For validating the email address
use Net::Ping;                        # For pinging
use MIME::Lite;                       # For sending email

# Determine hostname
my $HOSTNAME = `hostname`;

# Assume the localhost has an MTA running
my $MAIL_HOST = 'localhost';

# Specify a from address for the email message
my $FROM_ADDRESS = "ppping\@$HOSTNAME";

# How many seconds to sleep between pings
my $SLEEP_COUNT = 3;

#
# Send an email.  Call with a To: address and the message
# The message will be placed in the subject and the body
#
sub email
{
	my ( $to_address, $message ) = @_;

	my $mime_type = 'TEXT';
	my $message_body = "$message\n";

	# Create the initial text of the message
	my $mime_msg = MIME::Lite->new(
		From => $FROM_ADDRESS,
		To   => $to_address,
		Subject => $message,
		Type => $mime_type,
		Data => $message_body
	)
	or die ( "Error creating MIME body: $!\n" );

	# Send the Message
	MIME::Lite->send( 'smtp', $MAIL_HOST, Timeout=>60 );
	$mime_msg->send;
}

if ( $#ARGV != 2 )
{
	usage ();
}

my $IP_ADDRESS = $ARGV[0];
my $FAIL_COUNT = $ARGV[1];
my $EMAIL = $ARGV[2];

#
# imDead - Signal Handler Routine
#
sub imDead
{
	$SIG{INT} = \&imDead;

	email ($EMAIL, "$0 program terminated by Ctrl-C.  I'm not running!");
	die ( "\nCtrl-C pressed.  I'm dead and I'm telling! (mailto:$EMAIL)\n" );
}

# Validate the IP_ADDRESS
if(! is_ipv4($IP_ADDRESS))
{
	die( "Not an ip address.  Please use a valid IPV4 address.\n" );
}

# Validate the EMAIL address
if ( ! valid($EMAIL) )
{
	die ( "Not an RFC822 email address.  Please use a valid email address.\n" );
}

# Validate the FAIL_COUNT is numeric
if ( ! ($FAIL_COUNT =~ /^\d+$/ ) )
{
	die ( "Please specify a numeric failure_count (whole number, unsigned).\n" );
}

# Validate the FAIL_COUNT is a 'realistic' value
if ( ($FAIL_COUNT < 1) || ($FAIL_COUNT > 1000) )
{
	die ( "Please specify a numeric failure_count between 1 and 1000.\n" );
}

# Create a new "ping" object to use to ping
my $pping = Net::Ping->new();
( defined $pping ) or die ( "Couldn't create Net::Ping object: $!\n" );

# Keep track of the total ping failure count
my $fails = 0;

# Keep track of the total number of pings sent
my $numberOfPings = 0;

# Keep track the number of good pings in a row
my $goodPings = 0;

# If the host was down for FAIL_COUNT this will be set to 1
my $hostDown = 0;

while (1)
{

	$numberOfPings++;
	
	if ( $pping->ping($IP_ADDRESS) )
	{
		print ( "$numberOfPings\t$IP_ADDRESS\tAlive\n" );

		$goodPings++;

		# We have a good ping so the host is back up!
		if ( $fails >= $FAIL_COUNT )
		{
			print ( "$fails\t$IP_ADDRESS\tHost back up!\n" );
		}

		# Reset the fail count back to zero
		$fails = 0;

		# If the host was "down" and we have had FAIL_COUNT good pings
		# in a row send an email
		if ( ($hostDown == 1) && ($goodPings >= $FAIL_COUNT) )
		{
			print ( "$numberOfPings\t$IP_ADDRESS\tEmail sent to $EMAIL, up count ($FAIL_COUNT) reached!\n" );
			email ( $EMAIL, "Host UP: $IP_ADDRESS is now reachable $FAIL_COUNT times in a row." );
			$hostDown = 0;
		}
	} else
	{
		$fails++;
		$goodPings = 0;
		print ( "$numberOfPings\t$IP_ADDRESS\tDead ($fails/$FAIL_COUNT)\n" );
	}

	# If the host was not alreay in a down state, reaching the FAIL_COUNT will send an email
	if ( ($hostDown == 0) && ($fails == $FAIL_COUNT) )
	{
		print ( "$numberOfPings\t$IP_ADDRESS\tEmail sent to $EMAIL, failure count ($FAIL_COUNT) reached!\n" );
		email ( $EMAIL, "Host DOWN: $IP_ADDRESS is unreachable $FAIL_COUNT times in a row." );
		$hostDown = 1;
	}
	

	sleep ( $SLEEP_COUNT );
}

