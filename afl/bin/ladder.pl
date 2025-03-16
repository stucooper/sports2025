#!/usr/bin/perl
use strict;
use warnings;

use lib '/home/scooper/sports2025/afl/lib';
use AFL;

# This is the AFL version of the ladder generating program.
# The NRL one is in sports2025/nrl/bin/ladder.pl
# Produce the AFL ladder, from information in the results.tct files
my $resultsdir = $AFL::RESULTSDIR;
my %ladder = (); # multidimensional hash to generate the ladder
my %byethisround = ();

# can probably do the next foreach with a map but will foreach it for now
foreach (@AFL::Teams) {
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
my $i           = 1;
print "Pos TEAM  P  W  L  D   F    A     %   Pts\n";
foreach (@ladderTeams) {
    my $p  = $ladder{$_}{played};
    my $w  = $ladder{$_}{wins};
    my $l  = $ladder{$_}{losses};
    my $d  = $ladder{$_}{draws};
    my $f  = $ladder{$_}{for};
    my $a  = $ladder{$_}{against};
    my $po = $ladder{$_}{points};
    my $pct = 0; # club's percentage
    $pct = ($f/$a)*100.0 if ($a > 0);
    $pct = sprintf("%.1f", $pct); # to 1 decimal point
    #       Pos TEAM  P   W   L    D   F    A   %   PTS\n";
    printf("%3s %3s  %2s %2s %2s  %1s %4s %4s %6s %2s\n",
	     $i, $_, $p, $w, $l,  $d, $f, $a, $pct, $po);
    if ($i == 8 ) {
	# we have printed 8 positions of the ladder.. the top 8
	print "=========================================\n";
    }
    $i++;
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
		# drawn game: a bit more likely in AFL than NRL
		$ladder{$home}{draws}++;
		$ladder{$away}{draws}++;
		$ladder{$away}{points} += 2;
		$ladder{$home}{points} += 2;
		next;
	    }

	    if ( $homeScore > $awayScore ) {
		# home team wins
		$ladder{$home}{wins}++;
		$ladder{$home}{points} += 4;
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
	# split rounds. So I've changed it that a team with a bye is
	# explicitly mentioned in the
	# results file with BYE: TEAM1 TEAM2 TEAM3

	# On further consideration BYES might not be such a thing in the AFL
	# anyhow so if they don't affect the ladder in any way, I'll drop
	# the code below. As it stands, I haven't put any BYES: lines in
	# the results.txt AFL files so the below code doesn't execute.
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
    my @teams = @AFL::Teams;
    my @sorted = sort { $ladder{$b}{wins} <=> $ladder{$a}{wins}
			                   ||
 		        $ladder{$b}{played} <=> $ladder{$a}{played}
                                           ||
			$ladder{$b}{diff} <=> $ladder{$a}{diff}
			                   ||
			               $a cmp $b
    } @teams;
    # High to low sort, the earlier you are in the @sorted array the better
    # your ladder position. Most wins.. if wins are equal.. most games played..
    # if games are equal.. better percentage
    # if percentage equal (normally when teams haven't played yet)
    # just do alphabetical prdering.

    # Nitpicking note: My three-letter team abbreviations mean that
    # WCT sorts after WBD but for everyone else, Western Bulldogs is the
    # final team and West Coast is the second last team. This is extremely
    # nitpicking because after Round 01 every team will have played a game
    # and the absolute default alphabetical ordering $a cmp $b won't be used

    # FIXME: Do percentages properly at the moment I'm doing it on points diff
    # NRL-style.
    return(@sorted);
}
