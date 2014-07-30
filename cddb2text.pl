#!/usr/bin/perl -w
# Module derived from Armin Obersteiner <armin@xos.net>
# 	That module was CDDB_get-1.10
# New module cddb2text.pl by J.R.Spanier <jonathan@spanier.fsnet.co.uk>
#
#	Problem with renewing %cd hash table meant removing of this !!
#	Discovered CDDB server allows a maximum of 50 commands 
#				( pessimistic value / estimate )
#
{
use strict;
use IO::Socket;
use Getopt::Std;
use Term::ReadLine;		# tty access in addition to std streams
require "hostname.pl";
use vars qw/ $CDDB_HOST $CDDB_PORT $CLIENT $VERS $socket $return/;
use vars qw/ $enable $opt_e/;
use vars qw/ $termenable $abort/ ;

local $CDDB_HOST = "freedb.org";
local $CDDB_PORT = 8880;
local $CLIENT = "cddb2text.pl";
local $VERS = "v1.2006";
local $socket;
local $return;
my $send;
my $trans;
my $which;

$termenable = 'N' ;
$abort = 'N' ;

if ( ! getopts('e') ) {
	die("-e to enable database to stdout");
}

$enable = $opt_e ? 1 : 0;
$send = $ARGV[0];
$trans = $ARGV[1];
$which = $#ARGV;

if ( $which < 0 ) {
	die("no input file specified\n");
} elsif ( $which eq 0 ) {
	die("no output file specified\n");
} elsif ( $which > 1 ) {
	die("too many inputs\n");
}

if ( &connect() < 0 ) {
	exit;
}

# Poor new subroutine for ReadLine
# This creates a handle to tty to access the keyboard when stdin is
# not accessable.
my($term) ;
if ( $termenable eq "Y" ) {
$term = Term::ReadLine::new Term::Readline 'cddb2text.pl';
$term->ornaments(0);
}
# ornaments set to 0 imply no bold face for input text

# if input and output are '-' then select stdin and stdout respectively
# otherwise goto file specified.

open(IN,"$send");
if( ! -e $trans ) {
	open(OUT,"> $trans");
} else {
	open(OUT,">> $trans");
}

my $line;
my @strings = ();
my @data = ();
LINE: while($line = <IN>) {
	@data = split "'", $line;
	if ( $#data > 2 ) {
		my (@fix) = @data;
		shift(@fix);			# remove bottom stuff
		pop(@fix);			# remove final "'"
		$data[1] = join "'", @fix;
	}
	if ( $data[0] =~ /^restart/ ) {
		print $socket "quit\n";
		$return = <$socket>;
		my($err) = $return =~ /^(\d\d\d)\s+/;
		print STDERR "[R] $return";
		unless ($err =~ /^230/ ) {
		 chop($return);
		 chop($err);
		 print STDERR "[R] $return : $err\n";
		 print STDERR "quit error at cddb db: $CDDB_HOST:$CDDB_PORT\n";
		}
		close $socket;
		if ( &connect() < 0 ) {
			close IN;
			close OUT;
			exit;
		}
		next LINE;
	}

	@strings = split ' ',$data[0];
	my $tracks = $strings[1];
	print $socket "cddb query $data[0]\n";

	$return = <$socket>;
	print STDERR "[Q] $return";
	my ($err) = $return =~ /^(\d\d\d)\s+/;
	unless ($err =~ /^2/) {
		chop($return);
		chop($err);
		print STDERR "[Q] $return : $err\n";
		close $socket;
		close(OUT);
		close(IN);
		die "query error at cddb db: $CDDB_HOST:$CDDB_PORT";
	}

	my @list;
	@list = ();
	if($err==202) {
		print STDERR "Working on $data[1]\n" ;
		print STDERR "cddb no match for diskid: $strings[1]\n";
		next LINE; 
	} elsif ( $err == 211 ) {
		while(<$socket>) {
			last if (/^\./);
			push @list, $_;
		}

		my $n1;
		print STDERR "Working on $data[1]\n" ;
		print STDERR "This CD could be:\n\n";
		my $i = 1;
		foreach(@list) {
			my ($title) = $_ =~ /^\S+\s+\S+\s+(.*)/;
			print STDERR "$i: $title\n";
			$i++;
		}
		print STDERR "\n0: none of the above\n\n";
		my($prompt) = "Choose : ";
		my $n ;
		if ( $termenable eq 'Y' ) {
			$n = $term->readline($prompt);
		} else {
			$n = <STDIN> ;
		}
		$n1 = int($n) ;

		if ( $n1 == 0 ) {
			if ( $abort eq "Y" ) {
				print "nothing chosen - Aborting ...\n" ;
				close $socket ;
				close IN ;
				close OUT ;
				exit ;
			} else {
				print "nothing chosen - Continue ...\n" ;
				next LINE;
			}
		} else {
			$return = "200 " . $list[$n1-1];
		}

       } elsif($err == 200) {
		chop($return);
		print STDERR "[M] $return\n";
#		print STDERR "Exact match found\n";
       } else {
	print STDERR "cddb: unknown object\n";
	next LINE;
       }

      my($categ, $diskid, $at) = 
		$return =~ /^\d\d\d\s+(\S+)\s+(\S+)\s+(.*)/;

      my($artist, $title);

      if($at =~ /\//) {
	($artist,$title) = $at =~ /(.*?)\s*\/\s*(.*)/;
      } else {
	$artist = $at;
	$title = $at;
      }

      chop $title;
      chop $at;
      print OUT "ID=$diskid\nLOCATION=$data[1]\n";
      print OUT "TOTTRACKS=$tracks\nCDTITLE=$at\nCAT=$categ\n";
      print OUT "ARTIST=$artist\nALBUM=$title\n";

      print $socket "cddb read $categ $diskid\n";
	while(<$socket>) {
		next if(/^\d\d\d/);
		last if (/^\./);
		if($enable) {
			print STDOUT $_;
		}
		if(/^TTITLE(\d+)\=\s*(.*)/) {
			my $t = $2;
			chop $t;
			print OUT "TRACK $1=$t\n";
		}
	}
}

 print $socket "quit\n";
 $return = <$socket>;
 my($err) = $return =~ /^(\d\d\d)\s+/;
 chop($return);
 print STDERR "[EXIT] $return\n";
 unless ($err =~ /^230/ ) {
  chop($err);
  print STDERR "$return : $err\n";
  print STDERR "quit error at cddb db: $CDDB_HOST:$CDDB_PORT\n";
 }

 close $socket;                   
 close(IN);
 close(OUT);
}

sub connect {
	my($host);
	$host = &hostname;

	$socket = IO::Socket::INET->new(
			Proto => "tcp",
			Type  => SOCK_STREAM,
			PeerAddr => $CDDB_HOST,
			PeerPort => "$CDDB_PORT" );

	if ( ! $socket ) {
		 print STDERR 
			"Can't connect to port $CDDB_PORT on $CDDB_HOST : $!\n";
		 return -1;
	}

	$socket->autoflush(1);

	$return = <$socket>;
	unless ($return =~ /^2\d\d\s+/) {
		print STDERR "not welcome at cddb db\n";
		return -1;
	}

	print $socket "cddb hello $ENV{USER} $host $CLIENT $VERS\n";
	$return = <$socket>;
	unless ( $return =~ /^2\d\d\s+/) {
	 print STDERR "handshake error at cddb db: $CDDB_HOST:$CDDB_PORT\n";
	 return -1;
	}

	chop($return);
	print STDERR "[HELLO] $return\n";
	return 0;
}
