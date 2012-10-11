# This script will output messages that trigger your hilight to a 20x4 LCD screen running via LCDd/lcdproc
# TODO - Add commands for help, enable and disable.

use warnings;
use IO::Socket;
use Irssi;

our $VERSION = '1.01';
our %IRSSI = (
  authors     => 'shockwaver',
  contact     => 'irssi@shockwaver.org',
  name        => 'LCD Hilight',
  description => 'Script to send messages that trigger hilights to a 20x4 LCD screen',
  license     => 'Public Domain',
);

# scroller coords for line2, line3 and line4
my $line2coords="1 2";
my $line3coords="1 3 20 3 m 2";
my $line4coords="1 4 20 4 m 2";

init_lcd();

sub client_print {
	Irssi::print($_[0], MSGLEVEL_CLIENTCRAP);
}

sub init_lcd {
	client_print("irssi-lcd attempting to connect to lcdproc server... ");
	if ($lcd_handle = IO::Socket::INET->new(Proto     => "tcp", 
			PeerAddr  => "localhost", 
			PeerPort  => "13666"))
	{ 
		client_print("LCD connection established.."); 
		# establish lcd connection
		print $lcd_handle "hello\n";
		print $lcd_handle "client_set -name irssi\n";
		
		#add irssi screen
		print $lcd_handle "screen_add irssi\n";
		print $lcd_handle "screen_set irssi -name irssi\n";
		
		#initalization - drop priority to background
		print $lcd_handle "screen_set irssi -priority 224\n";
		
		#add widgets
		print $lcd_handle "widget_add irssi name title\n";
		print $lcd_handle "widget_add irssi line2 string\n";
		print $lcd_handle "widget_add irssi line3 scroller\n";
		print $lcd_handle "widget_add irssi line4 scroller\n";
		
		#show test pattern
		print $lcd_handle "widget_set irssi name irssi-lcd\n";
		print $lcd_handle "widget_set irssi line2 $line2coords \"irssi-lcd.pl loaded.\"\n";
		print $lcd_handle "widget_set irssi line3 $line3coords \"********************\"\n";
		print $lcd_handle "widget_set irssi line4 $line4coords \"--------------------\"\n";
	}
	else
	{ 
		client_print("LCD connection failure.");
		#socket enema
		$lcd_handle->autoflush(1);
		return 0;
	}
	return 1;
}

sub UNLOAD {
	print $lcd_handle "bye\n";
	client_print("LCD Connection shutdown.");
}

#this function handles splitting the message and outputting to the LCD screen.
sub lcd_print {
	my ($dest, $text, $stripped) = @_;
	my ($line2, $line3, $line4) = (" "," "," ");
	if (!(($dest->{level} & MSGLEVEL_HILIGHT) && ($dest->{level} & MSGLEVEL_PUBLIC))) {
		# Not a highlight message to a public channel
		return;
	}
	
	# extract nickname from format: <Username>
	$stripped=~m/<(.*?)\>.*/;
	my $nickname=$1;
	
	# break down the tweet in to LCd friendly lines
	# new regex <.*?> (.{0,20})(.{1,20})?\s(.*)
	# $1 is first 20 characters
	# $2 is next 20 characters, but will not break up a word at the end
	# $3 is the rest of the string

	# $stripped=~m/<.*> (.{0,20})(.{0,20})\s(.*)/;
	$stripped=~m/<.*?> (.{0,20})(.{1,20})?\s(.*)/;

	$line2=$1;
	# if we have a match on part two
	if ($2) {$line3=$2;}
	#if the match is on part 3, and part 2
	if ($3 && $2) {$line4=$3." -- ";}
	#if the match is on part 3, and not on part 2
	if ($3 && !$2) {$line3=$3; $line4=" ";}	
	
	if ($lcd_handle)
	{ 
		print $lcd_handle "hello\n";
		# we have a hilight - set priority to high to show immediately. Priority 16 will show instantly.
		print $lcd_handle "screen_set irssi -priority 16\n";
		# Set title as nickname from hilight message
		print $lcd_handle "widget_set irssi name \"$nickname\"\n";
		# Clear the screen before showing the tweet - this should prevent overlap issues
		print $lcd_handle "widget_set irssi line2 $line2coords \" \"\n";
		print $lcd_handle "widget_set irssi line3 $line3coords \" \"\n";
		print $lcd_handle "widget_set irssi line4 $line4coords \" \"\n";
		# Display the tweet strings
		print $lcd_handle "widget_set irssi line2 $line2coords \"$line2\"\n";
		print $lcd_handle "widget_set irssi line3 $line3coords \"$line3\"\n";
		print $lcd_handle "widget_set irssi line4 $line4coords \"$line4\"\n";
	} else {
		client_print("LCD connection failure.");
	}
}

# when called, lowers the priority of the screen to background
sub drop_priority {
	print $lcd_handle "hello\n";
	print $lcd_handle "screen_set irssi -priority 224\n";
}

Irssi::signal_add('print text', 'lcd_print');
# trigger on any key press - lower priority. Assumes the user has seen the message.
Irssi::signal_add('gui key pressed', 'drop_priority');

Irssi::command_bind('irssi-lcd', sub {
	if ($_[0] eq "restart" ) {
		UNLOAD();
		init_lcd();
	} else {
		client_print("irssi-lcd - Print hilights to external LCD screen.");
		client_print("  /irssi-lcd				Display this help.");
		client_print("  /irssi-lcd restart		Close and reopen LCD connection.");
	}
	Irssi::signal_stop;
}
);