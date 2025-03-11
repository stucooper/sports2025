#!/usr/bin/perl
use strict;
use warnings;

use lib '/home/scooper/sports2025/nrl/lib';
use NRL;

# Produce the NRL ladder, from information in the results.tct files
my $resultsdir = '/home/scooper/sports2025/nrl/results';
my %ladder = (); # multidimensional hash to generate the ladder
my %byethisround = ();

# can probably do the next foreach with a map but will foreach it for now
foreach (@NRL::Teams) {
    $byethisround{$_}    = 1;
    $ladder{$_}{played}  = 0;
    $ladder{$_}{wins}    = 0;
    $ladder{$_}{losses}  = 0;    
    $ladder{$_}{draws}   = 0;    
    $ladder{$_}{byes}    = 0;
    $ladder{$_}{for}     = 0;
    $ladder{$_}{against} = 0;
    $ladder{$_}{diff}    = 0;
}

opendir (my $resultsdirfh, $resultsdir)
    or die "cannot open $resultsdir: $!\n";

my @resultsfiles = grep { /.txt$/ } readdir $resultsdirfh;

foreach my $file (@resultsfiles) {
    processResultFile($file);
}

foreach (keys %byethisround ) {
    if ( $byethisround{$_} == 1 ) {
	$ladder{$_}{byes}++;
    }
}

my @ladderTeams = ladderPosition();
foreach (@ladderTeams) {
    print "$_\n";
}

sub processResultFile {
    my ($file) = @_;
    print "processing results file $file\n";    
    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    while (my $line = <$fh>) {
	chomp($line);
	print "found line $line\n";

	if ( $line =~ /\d{8}\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/ ) {
	    my($home,$homePoints,$away,$awayPoints) = ($1,$2,$3,$4);
	    $byethisround{$home} = 0;
	    $byethisround{$away} = 0;
	    $ladder{$home}{for}     += $homePoints;
	    $ladder{$home}{against} += $awayPoints;
	    $ladder{$away}{for}     += $awayPoints;
	    $ladder{$away}{against} += $homePoints;
	    $ladder{$home}{diff} += ($homePoints - $awayPoints);
	    $ladder{$away}{diff} += ($awayPoints - $homePoints);

	    if ( $homePoints == $awayPoints ) {
		# drawn game: less likely in NRL with Golden Point
		$ladder{$home}{draws}++;
		$ladder{$away}{draws}++;
		next;
	    }

	    if ( $homePoints > $awayPoints ) {
		# home team wins
		$ladder{$home}{wins}++;
		$ladder{$away}{losses}++;
		next;
	    }

	    if ( $homePoints < $awayPoints ) {
		# away team wins
		$ladder{$home}{losses}++;
		$ladder{$away}{wins}++;
		next;
	    }

	}
    }
}

sub ladderPosition {
    # input: the %ladder hash
    # output: an array of the team names from highest to lowest in the ladder
    return qw(MEL BRI MAN CAN BUL PEN NEW SOU GCT WTI
	      RED CRO STG AUK NQL ROO PAR);
}
