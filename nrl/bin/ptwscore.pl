#!/usr/bin/perl
use strict;
use warnings;

use lib '/home/scooper/sports2025/nrl/lib';
use NRL;

# Score a Pick the Winners NRL FootyTAB bet; using the results as
# we know them. A single argument filename is given which must be of
# the form ptw_roundNN.txt (use 05 for round 5).

# THIS PROGRAM SHOULD BE IDENTICAL TO afl/bin/ptwscore.pl except for
# using NRL.pm and /nrl/lib, /nrl/results directories not /afl/lib
# /afl/results directories. Diff the two programs after making
# changes. ptwscore is more important for NRL so the primary version
# that changes first will be nrl/bin/ptwscore.pl

my $betfile = $ARGV[0];
my $round;

# check that the betfile matches the required name
# word boundary the betfile could be in a different directory or this
# directory I thought about File::Basename but easiest just saying
# there needs to be a word boundary before ptw_round, that word
# boundary could be beginning of string ot directory /
# /x at the end of the regex so I can have a bit of whitespace in it
if ( $betfile =~ /\b ptw_round(\d\d).txt \Z/x ) {
    $round = $1;
}
else {
    die "ptw file needs to be called ptw_roundNN.txt";
}

print "Scoring Pick the Winners for Round $round\n";
open (my $betfh, '<', $betfile)
    or die "cannot open betfile $betfile: $!\n";

# print "Finding results file for round $round\n";
open (my $resultfh, '<', "$NRL::RESULTSDIR/round${round}.txt")
    or die "Cannot find results file for round $round\n";

# REQUIREMENT: Bets must be in the same order as the results
my $gamenum = 1;
my $correct = 0;

while ( my $betline = <$betfh> ) {
    chomp($betline);
    next if ( $betline =~ /^#/ );

    my ($teamPicked, $adj, $otherTeam, $winScore, $loseScore);
    if ( $betline =~ /\A\s*(\w\w\w)\s+([-+])([0-9.]*)/ ) {
	$teamPicked = $1;
	my $plusOrMinus = $2;
	$adj  = $3;
	if ($plusOrMinus eq '-') {
	    $adj = 0 - $adj; # or $adj *= -1;
	}
    }
    else
    {
	die "invalid betline: $betline\n";
    }
    print "Game $gamenum: $betline\n";
    # Find the result of this game, see REQUIREMENT
    my $resultline = <$resultfh>;

    # If we are running on a partial results file (eg Saturday morning
    # and only 3 games have been played and we just want to see we're
    # 3/3 so far) then $resultline will be undefined. Exit the program
    # with a suitable message.
    if (not defined ($resultline)) {
	die "No More results; more to come later.\n";
    }
    chomp($resultline);
    # I could regexp the resultline but stuff it I'll simply use split
    my ($t1, $t1score, $t2, $t2score);
    my %adjscore;
    (undef, $t1, $t1score, $t2, $t2score) = split /\s+/, $resultline; 
    if ( $t1 eq $teamPicked ) {
	$otherTeam = $t2;
	$loseScore = $t2score;
	$winScore = $t1score;
	$winScore += $adj;
    }
    elsif ( $t2 eq $teamPicked ) {
	$otherTeam = $t1;
	$loseScore = $t1score;
	$winScore = $t2score;
	$winScore += $adj;
    }
    else {
	die "Error: resultline $resultline does not contain $teamPicked\n";
    }
    print "$resultline  ";
    print "adjusted $teamPicked $winScore $otherTeam $loseScore\n";
    $correct++ if ($winScore > $loseScore);
    print "$correct/$gamenum\n";
    $gamenum++;
}

