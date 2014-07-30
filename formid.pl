#!/usr/bin/perl

$input = $ARGV[0];
if ( $input == "" ) {
	open(IN,"<&STDIN");
} else {
	open(IN,"$input");
}
$lines = 3;
$count = 0;
$var = "";
LINE: while(<IN>) {
	print $var;
	chop($_);
	if ( $count == 0) {
		$var = 	sprintf "\n\t\"$_\", ";
	} else {
		$var = sprintf "\"$_\", ";
	}
	$count++;
	$count %= $lines;
}
$var =~ s/$\,//g;
print $var;
print "\n";
close(IN);
