#!/usr/bin/perl
# This is the AFL version of the ladder generating program.
# The NRL one is in sports2025/nrl/bin/ladder.pl
# Produce the AFL ladder, from information in the results.txt files

use strict;
use warnings;

use Getopt::Std;
use lib '/home/scooper/sports2025/afl/lib';
use AFL;

our ($opt_n);

my $resultsdir = $AFL::RESULTSDIR;
my %ladder = (); # multidimensional hash to generate the ladder
my $stopRound = 100; # stop after this round
# $0 -n 2 stops the processing after Round 2 and reports ladder after then
# with no -n option stopRound is 100 and all results files processed
# $0 -n 2 == "this is what the ladder looked like after Round 2 finished"
getopts('n:');
if (defined $opt_n) {
    $stopRound = $opt_n;
}


# can probably do the next foreach with a map but will foreach it for now
foreach (@AFL::Teams) {
    $ladder{$_}{played}  = 0;
    $ladder{$_}{wins}    = 0;
    $ladder{$_}{losses}  = 0;    
    $ladder{$_}{draws}   = 0;    
    $ladder{$_}{for}     = 0;
    $ladder{$_}{against} = 0;
    $ladder{$_}{pct}     = 0;
    $ladder{$_}{points}  = 0;
}

opendir (my $resultsdirfh, $resultsdir)
    or die "cannot open $resultsdir: $!\n";

my @resultsfiles = grep { /.txt$/ } sort readdir $resultsdirfh;

foreach my $file (@resultsfiles) {
    processResultFile($file);
}

# quickly calculate the percentage for each team, before sorting into
# ladder position
foreach (@AFL::Teams) {
    my $f  = $ladder{$_}{for};
    my $a  = $ladder{$_}{against};
    my $pct = 0;
    $pct = ($f/$a)*100.0 if ($a > 0);
    $ladder{$_}{pct} = $pct;
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
    my $pct = $ladder{$_}{pct};
    $pct = sprintf("%.2f", $pct); # to 2 digits after decimal point
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
	next if ($line =~ /^#/);
        # print "found line $line\n";

        if ( $line =~ /\d{8}\s+(\w+)\s+(\d+)\s+(\w+)\s+(\d+)/ ) {
            my($home,$homeScore,$away,$awayScore) = ($1,$2,$3,$4);
            $ladder{$home}{for}     += $homeScore;
            $ladder{$home}{against} += $awayScore;
            $ladder{$away}{for}     += $awayScore;
            $ladder{$away}{against} += $homeScore;
            $ladder{$home}{played}++;
            $ladder{$away}{played}++;
            $ladder{$home}{pct} = ( $ladder{$home}{for}
                                    / $ladder{$home}{against} ) * 100.0;

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

        # AFL byes are zero points and don't get shown in the ladder so
        # there is no support for byes in this program. The NRL ladder.pl
        # shows byes and NRL teams get 2 points for their bye
        # but there is no need for it in AFL.

    }
}

sub ladderPosition {
    # input: the %ladder hash
    # output: an array of the team names from highest to lowest in the ladder
    my @teams = @AFL::Teams;
    my @sorted = sort { 4*$ladder{$b}{wins}
                                +
                        2*$ladder{$b}{draws} <=> 4*$ladder{$a}{wins}
                                                       +
			                         2*$ladder{$a}{draws}
                                           ||
                        $ladder{$b}{pct} <=> $ladder{$a}{pct}
                                           ||
                        $ladder{$b}{played} <=> $ladder{$a}{played}
                                           ||
                                       $a cmp $b
    } @teams;
    # High to low sort, the earlier you are in the @sorted array the better
    # your ladder position. Most wins.. if wins + draws are equal..
    # better precentage. if percentage equal (normally when teams
    # haven't played yet)  most games played
    # if games are equal.. just do alphabetical prdering.
    # AFL has stupid round00 "Opening" so the ladder in the first few weeks
    # is hardly worth looking at grrrrrr

    # Nitpicking note: My three-letter team abbreviations mean that
    # WCT sorts after WBD but for everyone else, Western Bulldogs is the
    # final team and West Coast is the second last team. This is extremely
    # nitpicking because after Round 01 every team will have played a game
    # and the absolute default alphabetical ordering $a cmp $b won't be used

    return(@sorted);
}
