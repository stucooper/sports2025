#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;
use lib '/home/scooper/sports2025/nrl/lib';
use NRL;

our ($opt_n, $opt_b);
# Generate my tipping score, using the results/ and tips/ files
my $resultsdir = $NRL::RESULTSDIR;
my $tipsdir    = $NRL::TIPSDIR;
my @teams      = @NRL::Teams;

# iTipFooty awards 2 bonus points for perfect tipped round. One day
# when I have a lot of time I'll implenet that feature, for now I'm
# just hard coding the number of bonus points I've got and I'll change
# the source code if I get more.
my $BONUS_POINTS = 2;
my $iTipFootyScore = 0;
my $totalGames  = 0;
my $winningTips = 0;
my $winningTipsThisRound = 0;
my $gamesThisRound = 0;
my %tippingEfficiency = (); # how good am I at tipping this team?
my %gamesPlayed = ();
my $breakdown = 0; # report tippingEfficiency results per team
my $stopRound = 100; # arbitrary large number there are never 100 rounds
# $0 -n 2 stops the processing after Round 2 and reports tipping up to then
# with no -n option stopRound is 100 and all results files processed
# $0 -n 2 == "this is what my tipping was like after Round 2 finished"

getopts('n:b');
if (defined $opt_b) {
    $breakdown = 1;
}
if (defined $opt_n) {
    $stopRound = $opt_n;
}


foreach (@teams) {
    $tippingEfficiency{$_} = 0;
    $gamesPlayed{$_} = 0;
}

opendir (my $resultsdirfh, $resultsdir)
    or die "cannot open $resultsdir: $!\n";

my @resultsfiles = grep { /.txt$/ } sort readdir $resultsdirfh;

foreach my $file (@resultsfiles) {
    processResultFile($file);
}

# This line is needed because I'm a tipscore.pl addict and
# run this program on the weekends in uncompleted rounds
# print "This Round: $winningTipsThisRound/$gamesThisRound\n";

$iTipFootyScore = $winningTips + $BONUS_POINTS;
print "
totalGames:  $totalGames
winningTips: $winningTips
iTipFooty:   $iTipFootyScore
";
my $tipPercentage = $winningTips * 100 / $totalGames;
printf("%.2f%%\n", $tipPercentage);

if ($breakdown) {
    foreach my $t (sort keys %tippingEfficiency) {
	print "$t $tippingEfficiency{$t}/$gamesPlayed{$t}\n";
    }
}

sub processResultFile {
    my ($file) = @_;
    my $round = 0;

    if ( $file =~ /round0?(\d+).txt/ ) {
	$round = $1;
	if ($round > $stopRound) {
	    return 1;
	}
    }

    print "processing results file $file...";
    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    open(my $tipfh, '<', "$tipsdir/$file")
	or die "cannot open tip file $tipsdir/$file: $!\n";
    $winningTipsThisRound = 0;
    $gamesThisRound = 0;
    
    while (my $line = <$fh>) {

	chomp($line);
	my ($teamTipped,$tippedToLose);
	# ASSUMPTION: The order of tips is the same as the order
	# of results.
	
	if ( $line =~ /\d{8}\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/ ) {
	    my($home,$homePoints,$away,$awayPoints) = ($1,$2,$3,$4);
	    $totalGames++;
	    $gamesThisRound++;
	    $gamesPlayed{$home}++;
	    $gamesPlayed{$away}++;
	    # read through the tips file until you get the next tip
	    my $tipFound = 0;

	    # need ($tipFound == 0) as the first clause of the while
	    # because if $tipFound == 1 we don't want to gobble the next tip
            # Boolean short-circuit we don't do <$tipfh> if tipFound == 0
	    while ( ($tipFound == 0) && defined(my $tipline = <$tipfh>) ) {
		chomp($tipline);
		if ($tipline =~ /^(\w{3})\s+[dD]\s+(\w{3})/) {
		    ($teamTipped,$tippedToLose) = ($1,$2);
		    $tipFound = 1;
		    # print "you tipped $teamTipped to beat $tippedToLose\n";
		    # print "result: $line\n";
		}
	    }
	    if ( $homePoints == $awayPoints ) {
		# drawn game: less likely in NRL with Golden Point
		# itipsfooty score you a winning tip for a draw
		# First draw was Round 10 MQL 30 PEN 30
		$winningTips++;
		$winningTipsThisRound++;
		$tippingEfficiency{$teamTipped}   += 1;
		$tippingEfficiency{$tippedToLose} += 1;
		next;
	    }

	    if ( $homePoints > $awayPoints ) {
		# home team wins
		if ( $home eq $teamTipped) {
		    $winningTips++;
		    $winningTipsThisRound++;
		    $tippingEfficiency{$teamTipped}   += 1;
		    $tippingEfficiency{$tippedToLose} += 1;
		}
		next;
	    }

	    if ( $homePoints < $awayPoints ) {
		# away team wins
		$winningTips++ if ( $away eq $teamTipped);
		next;
	    }

	}
    }

    print "$winningTipsThisRound/$gamesThisRound\n";
    # FIXME: The itipFooty comp I'm in has a "knockout comp" feature
    # where you pick one side each round (but not the same team in
    # consecutive rounds) that must win.. if your knockout side wins that
    # round you're still alive in the knockout competition going into
    # the next round. I could add support for that in this program
    # it'd be a bit tricky because the knockout team is mentioned at the
    # bottom of the tips file so I don't really know it in advance as
    # I parse down the results file line by line

    # I could have the knockout team at the top of the tips/ file without
    # crippling the file format too much, but I consider the knockout comp
    # itipFooty feature to be an adjunct to the main purpose of footy tipping
    # so having the knockout team at the top of the file annoys me
    # philosophically, it's just wrong.

    close($fh);
    close($tipfh);
}

