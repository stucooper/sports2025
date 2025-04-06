#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;
use lib '/home/scooper/sports2025/nrl/lib';
use NRL;

our ($opt_b);
# Generate my tipping score, using the results/ and tips/ files
my $resultsdir = $NRL::RESULTSDIR;
my $tipsdir    = $NRL::TIPSDIR;
my @teams      = @NRL::Teams;

my $totalGames  = 0;
my $winningTips = 0;
my $winningTipsThisRound = 0;
my $gamesThisRound = 0;
my %tippingEfficiency = (); # how good am I at tipping this team?
my %gamesPlayed = ();
my $breakdown = 0; # report tippingEfficiency results per team
getopts('b');
if (defined $opt_b) {
    $breakdown = 1;
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

print "
totalGames:  $totalGames
winningTips: $winningTips
";

# This line is needed because I'm a tipscore.pl addict and
# run this program on the weekends in uncompleted rounds
print "This Round: $winningTipsThisRound/$gamesThisRound\n";

if ($breakdown) {
    foreach my $t (sort keys %tippingEfficiency) {
	print "$t $tippingEfficiency{$t}/$gamesPlayed{$t}\n";
    }
}

sub processResultFile {
    my ($file) = @_;
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
		# FIXME: Once there is a drawn game, apply the itipsfooty
		#        policy to the score.. does a tipper score 1 or 0?
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

