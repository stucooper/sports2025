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

my @ladderTeams = ladderPosition();
foreach (@ladderTeams) {
    # FIXME: print out a nice formatted sprintf line of ladder
    print "$_ $ladder{$_}{diff} $ladder{$_}{byes}\n";
}

sub processResultFile {
    my ($file) = @_;
    print "processing results file $file\n";    
    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    while (my $line = <$fh>) {
	chomp($line);
	# print "found line $line\n";

	if ( $line =~ /\d{8}\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/ ) {
	    my($home,$homePoints,$away,$awayPoints) = ($1,$2,$3,$4);
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

	# Handle any BYE teams this round. I originally implemented this
	# as assume every time has a bye and set their bye to 0 once
	# I detect they've played this week, but then I thought of
	# State of Origin and split rounds. So I've changed it that
	# a team with a 2-point bye is explicitly mentioned in the
	# results file with BYE: TEAM1 TEAM2 TEAM3

	if ( $line =~ /BYES:\s+(.*)$/ ) {
	    my @byeTeams = split /\s+/, $1;
	    foreach (@byeTeams) {
		$ladder{$_}{byes}++;
	    }
	}

    }
}

sub ladderPosition {
    # input: the %ladder hash
    # output: an array of the team names from highest to lowest in the ladder
    my @teams = @NRL::Teams;
    my @sorted = sort { $ladder{$b}{wins} <=> $ladder{$a}{wins}
			                   ||
			$ladder{$b}{diff} <=> $ladder{$a}{diff}
			                   ||
			               $a cmp $b
    } @teams;
    # High to low sort, the earlier you are in the @sorted array the better
    # your ladder position. Most wins.. if wins are equal.. higher points diff
    # if points diff are equal (which they were for 4 teams after round 1
    # just do alphabetical prdering.

    return(@sorted);
}
