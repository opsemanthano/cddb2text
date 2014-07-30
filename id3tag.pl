#!/usr/bin/perl

use Getopt::Std;

if ( ! getopts('p') ) {
	die("-p to enable formatting for perl");
}

$sel = $opt_p ? 1 : 0;

$input = $ARGV[0];
open(IN,"$input");
LINE: while(<IN>) {
	next LINE unless ( /N_/);
	s#, #\n#g;
	s#^\s##g;
	if ( ! $sel ) {
		s#$\,##g;
	}
	s#N_\(\"(.*)\"\)#$1#g;
	push(@list,split '\n', $_);
	if ( ! $sel ) {
		print $_;
	}
}
close(IN);

if($sel) {
 print "\%id3tags = (\n";
 for($i=0;$i<=$#list;$i++) {
	$list[$i] =~ s#\W+##g;
	$list[$i] = lc($list[$i]);
	print "\t$list[$i] => $i, \n";
 }
 print ");\n";
}
