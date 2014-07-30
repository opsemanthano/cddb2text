#!/usr/bin/perl

$input = $ARGV[0];
$dbx = $ARGV[1];

open(IN,"$input");

$lines = 0;
while(<IN>) {
	@data = split "'", $_;
	if ( $#data > 2 ) {
		my(@fix) = @data;
		shift(@fix);
		pop(@fix);
		$data[1] = join "'", @fix;
	}
	@strings = split ' ', $data[0];
	if ( $strings[0] =~ /4b0aad08/ ) {
		# Steve Winwood / Back in the High Life
		$strings[0] = "4d0aaa08";	# matched to on CDDB server
	}
	$obj{$strings[0]} = $data[1];
}
close(IN);

@data = ();
open(IN,"$dbx");
LINE: while (<IN>) {
	chop($_);
	@data = split '=', $_;
	if ( /^ID=/ ) {
		$key = $data[1];
		print "ID=$key\n";
	} elsif ( /^LOCATION/ ) {
		$location = $obj{$key};
		print "LOCATION=$location\n";
	} else {
		print "$_\n";
	}
}
close(IN);
