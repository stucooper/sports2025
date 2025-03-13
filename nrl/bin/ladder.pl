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
    $ladder{$_}{points}  = 0;
}

opendir (my $resultsdirfh, $resultsdir)
    or die "cannot open $resultsdir: $!\n";

my @resultsfiles = grep { /.txt$/ } readdir $resultsdirfh;

foreach my $file (@resultsfiles) {
    processResultFile($file);
}

my @ladderTeams = ladderPosition();

# nrl.com has position team played points win drawn lost byes for against diff
# Adding position gives us a chance of a nice scary underline below the top 8
print "TEAM  P  W  D  L  B  F    A    +- Pts\n";
foreach (@ladderTeams) {
    my $p  = $ladder{$_}{played};
    my $w  = $ladder{$_}{wins};
    my $l  = $ladder{$_}{losses};
    my $d  = $ladder{$_}{draws};
    my $f  = $ladder{$_}{for};
    my $a  = $ladder{$_}{against};
    my $b  = $ladder{$_}{byes};
    my $pd = $ladder{$_}{diff};
    my $po = $ladder{$_}{points};
    printf("%3s  %2s %2s %2s  %2s %1s %4s %4s %4s %2s\n",
	     $_, $p, $w, $d, $l, $b,  $f, $a, $pd, $po);
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
	    my($home,$homeScore,$away,$awayScore) = ($1,$2,$3,$4);
	    $ladder{$home}{for}     += $homeScore;
	    $ladder{$home}{against} += $awayScore;
	    $ladder{$away}{for}     += $awayScore;
	    $ladder{$away}{against} += $homeScore;
	    $ladder{$home}{played}++;
	    $ladder{$away}{played}++;
	    $ladder{$home}{diff} += ($homeScore - $awayScore);
	    $ladder{$away}{diff} += ($awayScore - $homeScore);

	    if ( $homeScore == $awayScore ) {
		# drawn game: less likely in NRL with Golden Point
		$ladder{$home}{draws}++;
		$ladder{$away}{draws}++;
		$ladder{$away}{points}++;
		$ladder{$home}{points}++;
		next;
	    }

	    if ( $homeScore > $awayScore ) {
		# home team wins
		$ladder{$home}{wins}++;
		$ladder{$home}{points} += 2;
		$ladder{$away}{losses}++;
		next;
	    }

	    # FIXME: below code never executes because my results are
	    # always 20250308 WIN 16 LOS  4 so this never executes.
	    # I didn't have the points += 2 in the code but it didnt matter
	    # as code never executes
	    if ( $homeScore < $awayScore ) {
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
		$ladder{$_}{points} += 2;
	    }
	}

    }
}

sub ladderPosition {
    # input: the %ladder hash
    # output: an array of the team names from highest to lowest in the ladder
    my @teams = @NRL::Teams;
    my @sorted = sort { $ladder{$b}{points} <=> $ladder{$a}{points}
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
