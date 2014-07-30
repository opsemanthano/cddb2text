#!/usr/bin/perl 
{

use Getopt::Long;
# -save <filename>

require "find.pl";
require "pwd.pl";		# PERL track of current working directory
local $handle;			# access alternate filehandle within subroutine#				# by making it global in scope.
local $thru;

&initpwd;			# Current directory within $ENV{'PWD'}

GetOptions ( "save=s" => \$input,
	    "pass:s" => \$thru,
	    "lines:i" => \$quantity );

if ( $input eq "") {
 $temp = sprintf "Usage for $0\n%s%s%s\n",
     "--save <filename> : stdout (-) is available, disables further processing\n",
     "--pass <filename> : default to stdout\n",
     "--lines <number>  : default is 0, allows multiple calls to cddb server\n";
	die("$temp");
}

# protect $input from leading and trailing whitespace.
$input =~ s#^(\s)#./$1#;

while ($ARGV[0] =~ /^[^-!(]/ ) {
		push(@roots,shift);
}

@roots = ( '.') unless @roots;
for(@roots) { $_ = &quote($_); }
$roots = join(',',@roots);

#if ( $input =~ /^stdout/ ) {
#	open(SAVE,">&STDOUT");
#} else {
	open(SAVE,"> $input");
#}

$handle = \*SAVE;				# make $handle aliased to
						# the SAVE filehandle.
&find(eval($roots));
close(SAVE);

#if ( $input =~ /^stdout/ ) {
if (  $input eq "-" ) {
	print STDERR "Process can't continue as system can't reaccess stdout\n";
	exit -1;
}

 if ( process($name) < 0 ) {
	printf STDERR "Malformed Directory: multiple LOC= in file\n";
 }

}

sub process {
	my($name) = @_;
	my($time, $old, $flag, $index, @start);
	my(@strings, @parts);
	my($direct);
	my($diskid);
	my(@sorted);
	my($line,$linecount);
	$time = 0.0;
	$old = "";
	$flag = 0;
	$linecount = 0;
	@index = @start = ();
	
	if ($thru eq "") {
		open(FILOUT,">&STDOUT");
	} else {
		open(FILOUT,"> $thru");
	}

	open(FILEIN,"$input");
	while(<FILEIN>) {
		@strings = split 'LOC=', $_;
		if ($#strings ne 1) {
			close(FILEIN);
			close(FILOUT);
			return -1;
		}
		$direct = $strings[1];
		$direct =~ s#\n##;
		@parts = split ' ', $strings[0];
		if ( $old eq $direct || $old eq "") {
			$old = $direct;
			$diskid = $parts[0];
			push(@start,$parts[2]);
			$time = $time + scalar($parts[3]);
			$flag = 1;
		} elsif ( $flag = 1) {
			@sorted = sort { $a <=> $b } @start;
			$index = $#sorted + 1;
			$time = $time / 75;
			$line = sprintf "%s %s %s %s %s\n",
			    $diskid, $index, join(' ',@sorted),
			    $time, quote($old);
			print FILOUT "$line";
			if ( $quantity > 0 ) {
				$linecount++;
				if ( ! ($linecount % $quantity) ) {
					print FILOUT "restart\n";
				}
			}
			@start = ();
			$old = $direct;
			$diskid = $parts[0];
			push(@start,$parts[2]);
			$time = scalar($parts[3]);
			$flag = 0;
		}
	}
	@sorted = sort { $a <=> $b } @start;
	$index = $#sorted + 1;
	$time = $time / 75;
	$line = sprintf "%s %s %s %s %s\n",
		   $diskid, $index, join(' ',@sorted), $time, quote($old);
	if ( $quantity > 0 ) {
             $linecount++;
              if ( ! ($linecount % $quantity) ) {
                 print FILOUT "restart\n";
              }
        }     
	print FILOUT "$line";
	close(FILEIN);
	close(FILOUT);
	return 0;
}
			

sub quote {
	local($string) = @_;
	$string =~ s/'/\\'/;
	"'$string'";
}

sub wanted {
	/^.*\.inf$/ && &exec($name);
}

sub exec {
	local($name) = @_;
	local(@elements, $file, @parts, $index, $line);
	local($diskid, $start, $length);
	local($currentdir) = $ENV{'PWD'};
	@elements = split '/', $currentdir;
	pop(@elements);
	local($backdir);
	if ( $#elements > 0 ) {
		$backdir = join('/',@elements);
	} else {
		$backdir = "/";
	}
	@elements = ();
#	$name =~ s#^\.#$ENV{'PWD'}#;
#	$name =~ s#^(\s)#./$1#;
	$name =~ s#^\.\.#$backdir#;
	$name =~ s#^\.#$currentdir#;
	$name =~ s#^(\w)#$currentdir/$1#;
	@elements = split '/', $name;
	$file = $elements[$#elements];
	@parts = split '\.', $file;
	$index = $parts[0];
	$index =~ s/audio\_//g;
	pop(@elements);
	open(OBJECT,"$name\0") ||  die "Can't access $name : $!\n";
	while($line = <OBJECT>) {
		if ( $line =~ /^CDDB_DISCID/ ) {
			@parts = split '=', $line;
			$diskid = (split('x',$parts[1]))[1];
			chop($diskid);
		}
		if ( $line =~ /^Trackstart/ ) {
			@parts = split ' ', $line;
			$start = $parts[1];
		}
		if ( $line =~ /^Tracklength/ ) {
			@parts = split ' ', $line;
			$length = $parts[1];
			$length =~ s/,//g;
		}
	}
	$name = join('/',@elements);
	print $handle "$diskid $index $start $length LOC=$name\n";
	close(OBJECT);
}
