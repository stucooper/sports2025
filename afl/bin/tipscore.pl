#!/usr/bin/perl
# Generate my tipping score, using the results/ and tips/ files
# The tipping comp I am in is Official AFL tipping and has two
# side-games on top of straight up tipping. There are called Gauntlet
# and Min5.

use strict;
use warnings;

use Getopt::Std;
use lib '/home/scooper/sports2025/afl/lib';
use AFL;

our ($opt_n, $opt_b, $opt_g);

my $resultsdir = $AFL::RESULTSDIR;
my $tipsdir    = $AFL::TIPSDIR;
my @teams      = @AFL::Teams;

my $totalGames  = 0;
my $winningTips = 0;
my $winningTipsThisRound = 0;
my $gamesThisRound = 0;
my %tippingEfficiency = (); # how good am I at tipping this team?
use constant GAUNTLET_START_ROUND => 7;
my %gauntletTips = (); # have I tipped this team in Gauntlet side-game?
my %gamesPlayed = ();
my $breakdown = 0; # report tippingEfficiency results per team
my $show_gauntlet = 0; # -g option
my $stopRound = 100; # arbitrary large number there are never 100 rounds
# $0 -n 2 stops the processing after Round 2 and reports tipping up to then
# with no -n option stopRound is 100 and all results files processed
# $0 -n 2 == "this is what my tipping was like after Round 2 finished"
# Because of stupid AFL numbering the first Opening Round is Round 0 so
# the earliest you can stop this is $0 -n 0 when you get the 2 Opening games
getopts('n:bg');
if (defined $opt_n) {
    $stopRound = $opt_n;
}
if (defined $opt_b) {
    $breakdown = 1;
}
if (defined $opt_g) {
    $show_gauntlet = 1;
}

# Minimum 5 side-game: Correctly tip 5 or more tips per round
# starting from Round 11 (not Round 1 as previously thought!!)
my $aliveInMin5 = 1;

# Gauntlet side game: from Round 7 onwards you pick a Gauntlet team
# (needs to be unique across the rounds) and that team needs to win
# for you to stay alive in the Gauntlet competition
my $gauntletActive = 0;

foreach (@teams) {
    $tippingEfficiency{$_} = 0;
    $gamesPlayed{$_} = 0;
    $gauntletTips{$_} = 0;
}

opendir (my $resultsdirfh, $resultsdir)
    or die "cannot open $resultsdir: $!\n";

my @resultsfiles = grep { /.txt$/ } sort readdir $resultsdirfh;

opendir (my $tipsdirfh, $tipsdir)
    or die "cannot open $tipsdir: $!\n";

foreach my $file (@resultsfiles) {
    processResultFile($file);
}

# This line is needed because I'm a tipscore.pl addict and
# run this program on the weekends in uncompleted rounds
# print "This Round: $winningTipsThisRound/$gamesThisRound\n";

print "
totalGames:  $totalGames
winningTips: $winningTips
";
my $tipPercentage = $winningTips * 100 / $totalGames;
printf("%.2f%%\n", $tipPercentage);


# 18 teams.. do the breakdown in three columns six rows
if ($breakdown) {
    print "\nTIPPING EFFICIENCY\n";
    my $col = 0;
    foreach my $t (sort keys %tippingEfficiency) {
	print "$t $tippingEfficiency{$t}/$gamesPlayed{$t}   ";
	$col++;
	if ( $col == 3 ) {
	    print "\n";
	    $col = 0;
	}
    }
    print "\n";
}

if ( $aliveInMin5 ) {
    print "Still alive in Min5\n";
}
else {
    print "Lost in Min5\n";
}

if ( $show_gauntlet ) {
    print "\nGAUNTLET TIPS\n";
    my $col = 0;
    foreach my $t (sort keys %gauntletTips) {
	my $display = $gauntletTips{$t};
	$display = q{ } if ( $display == 0 );
	$display = sprintf "%2s", $display;
	print "$t $display   ";
	$col++;
	if ( $col == 3 ) {
	    print "\n";
	    $col = 0;
	}
    }
    print "\n";
}

# I'm thinking of making gauntletActive a tri-state variable
# 0 : not active yet (rounds 0-6)
# 1 : active and I'm still alive in the minigame
# -1 : I'm out
# The main use of this is the message below could say "dead in Gauntlet"
if ( $gauntletActive == 1 ) {
    print "Alive in Gauntlet\n";
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
	if ($round == GAUNTLET_START_ROUND ) {
	    $gauntletActive = 1;
	}
    }
    else {
	die "Cannot figure out round number from filename $file\n";
    }

    print "processing results file $file..";

    # It seems to me I'm doing this wrong-way-around
    # Read the tips file first.. this will also tell us
    # the number of games for this round (we can assume
    # the tips file is complete).
    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    open(my $tipfh, '<', "$tipsdir/$file")
	or die "cannot open tip file $tipsdir/$file: $!\n";

    $gamesThisRound = 0;
    $winningTipsThisRound = 0;
    my $gauntletTip = 'UNSET';

    while (my $line = <$fh>) {

	chomp($line);
	my ($teamTipped,$tippedToLose);

	# ASSUMPTION: The order of tips is the same as the order
	# of results. But if I read the tipsfiles first this will be moot.
	
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
		if ( $tipline =~ /^GAUNTLET:\s+(\w{3})\s*$/ ) {
		    $gauntletTip = $1;
		    if ( $show_gauntlet ) {
			print "..GNT $gauntletTip...";
		    }
		    if ( ! $gauntletActive ) {
			die "Gauntlet tip found but gauntlet not active\n";
		    }

		    my $gtr = $gauntletTips{$gauntletTip};
		    if ( $gtr != 0 ) {
			die "your gauntletTip of $gauntletTip was used in round $gtr\n";
		    }
		    else {
			$gauntletTips{$gauntletTip} = $round;
		    }
		}
	    }
	    if ( $homePoints == $awayPoints ) {
		# drawn game.
		# The AFL tipping competition awards 1 for a drawn tip
		$winningTips++;
		$winningTipsThisRound++;
		$tippingEfficiency{$teamTipped}   += 1;
		$tippingEfficiency{$tippedToLose} += 1;
		# Note: a draw does not kill your GauntletTip.
		# (Round 9 Brisbane v North drawn)
		next;
	    }

	    if ( $homePoints > $awayPoints ) {
		# home team wins
		if ( $home eq $teamTipped) {
		    $winningTips++;
		    $winningTipsThisRound++;
# If we want to have maximum efficiency we only need to perform
# the next two lines if $breakdown != 0
		    $tippingEfficiency{$teamTipped}   += 1;
		    $tippingEfficiency{$tippedToLose} += 1;
# But I'm lazily computing it regardless, even if we're not
# going to report on it.
# End of $breakdown != 0 comment
		}
		if ( $away eq $teamTipped) {
                    # losing tip; kill the gauntlet if that's your tip
		    if ( $gauntletActive && ( $away eq $gauntletTip ) ) {
			# print "lost gauntlet you said $home d $away\n";
			$gauntletActive = 0;
		    }
                }
		next;
	    }

	    if ( $homePoints < $awayPoints ) {
		# NOTREACHED
		# SHOULD NEVER HAPPEN BECAUSE I PUT MY RESUTS AS
		# 20250419 ADE  52 GWS  34
		# So $homePoints >= $awayPoints
		$winningTips++ if ( $away eq $teamTipped);
		next;
	    }

	} # if $line =~ a results line
    }

    print "$winningTipsThisRound/$gamesThisRound\n";
    # TODO: Add support for the margin feature of AFL tipping.
    # In Round 00 I said Syd d Haw by 16, in the event Haw wom by 20
    # so my margin score is 36 and gets added to each round. The lower
    # your margin score, the better.

    # Minimum 5 "Min5" Minigame. Starts in Round 11, I'd thought Round 1
    # Correctly tip 5 or more tips per round.

    # WHAT THE ACTUAL?? APPARENTLY MIN5 STARTS IN ROUND11 NOT
    # ROUND 1. I THOUGHT THE WEBSITE SAID ROUND 1! BUT IT LOOKS LIKE
    # IT'S BEEN ROUND11 ALL THIS TIME. HERE I AM WASTING TIME AND
    # ENERGY WORRIED THAT MY 2/6 EASTER TIPS WOULDN'T MIN5 AND BEING
    # DELIGHTED THAT THEY DID WHEN I FINISHED 5/9 WHEN ALL ALONG MIN5
    # DOESN'T START UNTIL ROUND 11. I AM ANNOYED ENOUGH AT THIS TO
    # SHOUT AN ALL-CAPS COMMENT. STOP RUINING MY LIFE, AFL!

    # I'm such an addict of tipscore.pl that I run it on weekends
    # in uncompleted rounds... the code below tries to
    # not mark me as dead in Min5 unless the round is complete or
    # I'm too far behind to catch up to 5/9 tips

    # Actually there should be a heuristic to know if min5 is dead no matter
    # how few games are played.. if you're more than 5 tips down you're out
    # eg you've tipped 1 out of 6 you're out because most you'll get is
    # 3 out of 8. You need to be at least 5/8 or 4/7 or 3/6 or 2/5 or 1/4,
    # in an 8-round match, to be able to tip 5.
    # So gamesPlayed - winningTipsThisRound <= 4

    # It sounds like Matchplay Golf where if you're 2 behind with 3 to play
    # you're ok but if you're 3 behind with 2 to play, game over.

    # Are we dead in min5?
    if ( $round <= 10 ) {
	# min5 starts at Round 11 FFS. SEE SHOUTY COMMENT ABOVE
	;
    }
    else {
	my $behind = $gamesThisRound - $winningTipsThisRound;
	if ( $behind > 4 ) {
            # you're too far behind you can't catch up you can't tip 5/9
            # no matter how good the rest of your tips this round
	    $aliveInMin5 = 0;
	}
	# FIXME: If there are only 8 games this round, and the round is
	# complete and you only scored 4/8 you are dead in Min5.
	# This is tricky because I could be running tipscore in a 9 match
	# round with the 9th game in Western Australia and the same
	# score of 4/8 but still be alive with one game to play. Tricky!!

	# Also notice that we set aliveInMin5 to 1 at the top of the program
	# but we don't re-set it to 1 anywhere else. Once you're dead in Min5
	# you STAY dead. If you're 4/9 in Round 13 and 9/9 in Round 14 you're
	# still dead in Min5 since you lost that minigame forever in Round13.
    }


    close($fh);
    close($tipfh);
}

