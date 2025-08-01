#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;
use lib '/home/scooper/sports2025/nrl/lib';
use NRL;

our ($opt_n);

# Produce the NRL ladder, from information in the results.txt files
my $resultsdir = $NRL::RESULTSDIR;
my %ladder = (); # multidimensional hash to generate the ladder
my %byethisround = ();
my $stopRound = 100; # stop after this round
# $0 -n 2 stops the processing after Round 2 and reports ladder after then
# with no -n option stopRound is 100 and all results files processed
# $0 -n 2 == "this is what the ladder looked like after Round 2 finished"
getopts('n:');
if (defined $opt_n) {
    $stopRound = $opt_n;
}

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

my @resultsfiles = grep { /.txt$/ } sort readdir $resultsdirfh;

foreach my $file (@resultsfiles) {
    processResultFile($file);
}

my @ladderTeams = ladderPosition();
my $i           = 1;
# nrl.com has position team played points win drawn lost byes for against diff
# Adding position gives us a chance of a nice scary underline below the top 8
print "Pos TEAM  P  W  D  L  B   F    A   +- Pts\n";
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
    printf("%3s %3s  %2s %2s %2s  %2s %1s %4s %4s %4s %2s\n",
	     $i, $_, $p, $w, $d, $l, $b,  $f, $a, $pd, $po);
    if ($i == 8 ) {
	# we have printed 8 positions of the ladder.. the top 8
	print "=========================================\n";
    }
    $i++;
}

sub processResultFile {
    my ($file) = @_;
    my $round = 0;

    if ( $file =~ /round0?(\d+).txt/ ) {
        $round = $1;
        if ($round > $stopRound) {
            return 1;
        }
        # print "Using round $round\n";
    }
    else {
        die "Cannot figure out round number from filename $file\n";
    }

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
	# as assume every team has a bye and set their bye to 0 once
	# I detect they've played this week, but then I thought of
	# State of Origin and split rounds. So I've changed it that
	# a team with a 2-point bye is explicitly mentioned in the
	# results file with BYES: TEAM1 TEAM2 TEAM3

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
