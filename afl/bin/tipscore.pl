#!/usr/bin/perl
use strict;
use warnings;

use lib '/home/scooper/sports2025/afl/lib';
use AFL;

# Generate my tipping score, using the results/ and tips/ files
# The tipping comp I am in is Official AFL tipping and has seveal
# side-games on top of straight up tipping, I will add support for
# them if I can; there are comments at the bottom of the file about
# the side-game features

my $resultsdir = $AFL::RESULTSDIR;
my $tipsdir    = $AFL::TIPSDIR;
my @teams      = @AFL::Teams;

my $totalGames  = 0;
my $winningTips = 0;
my $winningTipsThisRound = 0;
my $gamesThisRound = 0;
my %tippingEfficiency = (); # how good am I at tipping this team?
my %gamesPlayed = ();
my $stopRound = 100; # arbitrary large number there are never 100 rounds
# I will add a cmdline argument that will stop tipping after that round
# eg tipscore.pl -n 3 will stop after round 3

# Minimum 5 side-game: Correctly tip 5 or more tips per round
# starting from Round 01
my $aliveInMin5 = 1;

foreach (@teams) {
    $tippingEfficiency{$_} = 0;
    $gamesPlayed{$_} = 0;
}

opendir (my $resultsdirfh, $resultsdir)
    or die "cannot open $resultsdir: $!\n";

my @resultsfiles = grep { /.txt$/ } sort readdir $resultsdirfh;

opendir (my $tipsdirfh, $tipsdir)
    or die "cannot open $tipsdir: $!\n";

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

foreach my $t (sort keys %tippingEfficiency) {
    print "$t $tippingEfficiency{$t}/$gamesPlayed{$t}\n";
}

if ( $aliveInMin5 ) {
    print "Still alive in Min5\n";
}
else {
    print "Lost in Min5\n";
}

sub processResultFile {
    my ($file) = @_;
    my $round = 0;

    print "processing results file $file\n";    

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

    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    open(my $tipfh, '<', "$tipsdir/$file")
	or die "cannot open tip file $tipsdir/$file: $!\n";

    $gamesThisRound = 0;
    $winningTipsThisRound = 0;
    
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
		# drawn game, sometimes happens in AFL
		# FIXME: Once there is a drawn game, apply the AFL tipping
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

    # TODO: Add support for the margin feature of AFL tipping.
    # In Round 00 I said Syd d Haw by 16, in the event Haw wom by 20
    # so my margin score is 36 and gets added to each round. The lower
    # your margin score, the better.

    # TODO: From Round 7, AFL tipping has a "Gauntlet" competition.
    # Pick a team each round to win, but never the same team in the next
    # Gauntlet round. This seems to be the same as the "Knockout" feature
    # in my NRL tipping comp; see the long FIXME in nrl/bin/tipscore.pl

    # TODO: I'm such an addict of tipscore.pl that I run it on weekends
    # in uncompleted rounds... the code below needs to be augmented so
    # that it doesn't mark me as dead in Min5 unless the round is complete
    if ( $round > 0 && $winningTipsThisRound < 5 ) {
	print "min5 dead in round $round\n";
	$aliveInMin5 = 0;
    }

    close($fh);
    close($tipfh);
}

