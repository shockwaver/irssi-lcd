# This script will output messages that trigger your hilight to a 20x4 LCD screen running via LCDd/lcdproc
# /irssi-lcd help to view options

use warnings;
use IO::Socket;
use Irssi;

our $VERSION = '1.00';
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
	client_print("irssi-lcd Attempting to connect to lcdproc server... ");
	if ($lcd_handle = IO::Socket::INET->new(Proto     => "tcp", 
			PeerAddr  => "localhost", 
			PeerPort  => "13666"))
	{ 
		client_print("Successfully connected to lcdproc server."); 
		# establish lcd connection
		print $lcd_handle "hello\n";
		print $lcd_handle "client_set -name irssi\n";
		
		#add irssi screen
		print $lcd_handle "screen_add irssi\n";
		print $lcd_handle "screen_set irssi -name irssi\n";
		
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

sub disable_lcd {
	print $lcd_handle "bye\n";
	client_print("LCD Connection shutdown.");
}

#this function handles splitting the message and outputting to the LCD screen.
sub lcd_print {
	my ($dest, $text, $stripped) = @_;
	# Irssi::print("init text: $text", MSGLEVEL_CLIENTCRAP);
	print $text;
	if (!(($dest->{level} & MSGLEVEL_HILIGHT) && ($dest->{level} & MSGLEVEL_PUBLIC))) {
		# Not a highlight message to a public channel
		return;
	}
	
	# extract nickname from format: <Username>
	$text=~m/<(.*)\>.*/;
	my $nickname=$1;
	
	# break down the tweet in to LCd friendly lines
	# new regex (.{0,20})(.{0,20})\s(.*)
	# $1 is first 20 characters
	# $2 is next 20 characters, but will not break up a word at the end
	# $3 is the rest of the string

	$text=~m/<.*> (.{0,20})(.{0,20})\s(.*)/;
	# client_print("text after split: $text");
	$line2=$1;
	$line3=$2;
	$line4=$3." -- ";
	# client_print("line2: $1");
	# client_print("line3: $2");
	# client_print("line4: $3");
	
	
	if ($lcd_handle)
	{ 
		print $lcd_handle "hello\n";
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

# Irssi::signal_add('print text', 'lcd_print');