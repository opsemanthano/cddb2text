#!/usr/bin/perl

use Getopt::Std;

if( ! getopts('-d') ) {
	die("-d to stop system calls to id3 and print commands to stdout");
}

$disable = $opt_d ? 1 : 0;

%id3tags = (
	blues => 0, 
	classicrock => 1, 
	country => 2, 
	dance => 3, 
	disco => 4, 
	funk => 5, 
	grunge => 6, 
	hiphop => 7, 
	jazz => 8, 
	metal => 9, 
	newage => 10, 
	oldies => 11, 
	other => 12, 
	pop => 13, 
	rb => 14, 
	rap => 15, 
	reggae => 16, 
	rock => 17, 
	techno => 18, 
	industrial => 19, 
	alternative => 20, 
	ska => 21, 
	deathmetal => 22, 
	pranks => 23, 
	soundtrack => 24, 
	eurotechno => 25, 
	ambient => 26, 
	triphop => 27, 
	vocal => 28, 
	jazzfunk => 29, 
	fusion => 30, 
	trance => 31, 
	classical => 32, 
	instrumental => 33, 
	acid => 34, 
	house => 35, 
	game => 36, 
	soundclip => 37, 
	gospel => 38, 
	noise => 39, 
	alt => 40, 
	bass => 41, 
	soul => 42, 
	punk => 43, 
	space => 44, 
	meditative => 45, 
	instrumentalpop => 46, 
	instrumentalrock => 47, 
	ethnic => 48, 
	gothic => 49, 
	darkwave => 50, 
	technoindustrial => 51, 
	electronic => 52, 
	popfolk => 53, 
	eurodance => 54, 
	dream => 55, 
	southernrock => 56, 
	comedy => 57, 
	cult => 58, 
	gangstarap => 59, 
	top40 => 60, 
	christianrap => 61, 
	popfunk => 62, 
	jungle => 63, 
	nativeamerican => 64, 
	cabaret => 65, 
	newwave => 66, 
	psychedelic => 67, 
	rave => 68, 
	showtunes => 69, 
	trailer => 70, 
	lofi => 71, 
	tribal => 72, 
	acidpunk => 73, 
	acidjazz => 74, 
	polka => 75, 
	retro => 76, 
	musical => 77, 
	rockroll => 78, 
	hardrock => 79, 
	folk => 80, 
	folkrock => 81, 
	nationalfolk => 82, 
	swing => 83, 
	fastfusion => 84, 
	bebob => 85, 
	latin => 86, 
	revival => 87, 
	celtic => 88, 
	bluegrass => 89, 
	avantgarde => 90, 
	gothicrock => 91, 
	progressiverock => 92, 
	psychedelicrock => 93, 
	symphonicrock => 94, 
	slowrock => 95, 
	bigband => 96, 
	chorus => 97, 
	easylistening => 98, 
	acoustic => 99, 
	humour => 100, 
	speech => 101, 
	chanson => 102, 
	opera => 103, 
	chambermusic => 104, 
	sonata => 105, 
	symphony => 106, 
	bootybass => 107, 
	primus => 108, 
	porngroove => 109, 
	satire => 110, 
	slowjam => 111, 
	club => 112, 
	tango => 113, 
	samba => 114, 
	folklore => 115, 
	ballad => 116, 
	powerballad => 117, 
	rhythmicsoul => 118, 
	freestyle => 119, 
	duet => 120, 
	punkrock => 121, 
	drumsolo => 122, 
	acappella => 123, 
	eurohouse => 124, 
	dancehall => 125, 
	goa => 126, 
	drumbass => 127, 
	clubhouse => 128, 
	hardcore => 129, 
	terror => 130, 
	indie => 131, 
	britpop => 132, 
	negerpunk => 133, 
	polskpunk => 134, 
	beat => 135, 
	christiangangstarap => 136, 
	heavymetal => 137, 
	blackmetal => 138, 
	crossover => 139, 
	contemporarychristian => 140, 
	christianrock => 141, 
	merengue => 142, 
	salsa => 143, 
	thrashmetal => 144, 
	anime => 145, 
	jpop => 146, 
	synthpop => 147
);

$input = $ARGV[0];

if ( $input eq "" ) {
	open(IN,"<&STDIN");
} else {
	open(IN,"$input");
}

$lines = 0;
LINE: while(<IN>) {
	chop($_);
	@data = split '=', $_;
	if ( $#data > 1) {
		print "oops: need to rejoin 1 .. infinty\n";
	}
	if ( /^ID=/ ) {
		$new = $data[1];
	} elsif ( /^LOCATION/ ) {
		$location = $data[1];
	} elsif ( /^TOTTRACKS/ ) {
		$tottracks = $data[1];
	} elsif ( /^CAT/ ) {
		$cat = $data[1];
		$cat =~ s/misc/other/;
	} elsif ( /^ALBUM/ ) {
		$album = $data[1];
	} elsif ( /^ARTIST/ ) {
		$artist = $data[1];
	} elsif ( /^TRACK/ ) {
		@index = split ' ', $data[0];
		$trackno = sprintf "%02d", $index[1] + 1; # don't start at track
							  # zero, always at 1.
#		$file = sprintf "%s/audio_%s.mp3", $location, $trackno;
			$newfile = sprintf "%s - %s - %s - %s.mp3",
					$artist, $album, $trackno, $data[1];
			$newfile =~ s/\//\\/g;	# clobber '/' into '\'
			$location =~ s#\\'#'#g;	# clobber "\'" into "'"
						# caused by grab.pl
		$file = sprintf "%s/%s", $location, $newfile;
		if ( -e $file ) {
#
#	length is really 30 including '"'. As there are two '"', we have
#	the magic number 28
#
			if(length($album) > 28 || length($data[1]) > 28
						|| length($artist) > 28 ) {
				$tagmode = "-2";
			} else {
				$tagmode = "-1";
			}
			
			@cmds = ();
			push(@cmds,'id3convert');
			push(@cmds,"-s");
			push(@cmds,"$file");
			if ( ! $disable ) {
				system(@cmds);
			} else {
				$scan = join(' ',@cmds);
				print "$scan\n";
			}
			@cmds = ();
			push(@cmds,'id3tag');
			push(@cmds,$tagmode);
			push(@cmds,"-a"); push(@cmds,"\"$artist\"");
			push(@cmds,"-s"); push(@cmds,"\"$data[1]\"");
			push(@cmds,"-A"); push(@cmds,"\"$album\"");
			push(@cmds,"-g"); push(@cmds,$id3tags{$cat});
			push(@cmds,"-t"); push(@cmds,$trackno);
			if ( $tottracks ne 0) {
			   push(@cmds,"-T"); push(@cmds, $tottracks);
			}
			push(@cmds,$file);
			if ( ! $disable) {
				system(@cmds);
			#	rename $file, "$location/$newfile";
			} else {
				$scan = join(' ',@cmds);
				print "$scan\n";
			#	print "rename $file $location/$newfile\n";
			}
		} else {
			printf STDERR "OOPS: ERROR accessing %s within %s\n",
					$file, $lines + 1;
		}
	}
	$lines++;
}
close(IN);
