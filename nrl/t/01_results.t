#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/nrl/lib";
use Test::More;
# Number of tests: 1 + number of results files


use_ok('NRL');
my $testsRun = 1;

my $resultsdir = $NRL::RESULTSDIR;

opendir(my $resultsdirfh, $resultsdir)
    or die "Cannot open resultsdir $resultsdir: $!\n";

my (@resultsfiles) = grep{ /\.txt$/ && -f "$resultsdir/$_" } 
                        sort readdir ($resultsdirfh);

foreach my $file (@resultsfiles) {
    my $i = processResultsFile($file);
    is($i, 1, "results file $file clean");
    $testsRun++;
}

done_testing($testsRun);

sub processResultsFile {
    my ($file) = @_;
    my $date = 0;
    my $allResultsIn = 0;
    my @teams = @NRL::Teams;
    my %teamPlayed;
    foreach (@teams) {
	$teamPlayed{$_} = 0;
    }
    
    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    while (my $line = <$fh>) {
	chomp($line);
	next if ($line =~ /^#/ ); # ignore column 1 comments
	if ( $line =~ /(\d{8})\s+(\w+)\s+\d+\s+(\w+)\s+\d+/ ) {
	    my ($matchDate, $homeTeam, $awayTeam) = ($1,$2,$3);
	    if ($matchDate < $date) {
		print STDERR "date error $matchDate earlier than $date\n";
                return 0;
	    }
	    $date = $matchDate;
	    if ( ! defined($teamPlayed{$homeTeam}) ) {
	     	print STDERR "team error: unknown team $homeTeam\n";
                return 0;
	    }
	    if ( ! defined($teamPlayed{$awayTeam}) ) {
                print STDERR "team error: unknown team $awayTeam\n";
                return 0;
	    }
	    if ( ( $teamPlayed{$homeTeam} == 1 ) ) {
                print STDERR "team error: $homeTeam already played\n";
                return 0;
	    }
	    if ( ( $teamPlayed{$awayTeam} == 1 ) ) {
                print STDERR "team error: $awayTeam already played\n";
                return 0;
	    }
	    $teamPlayed{$homeTeam} = 1;
	    $teamPlayed{$awayTeam} = 1;
	}
	if ( $line =~ /BYES:\s+(.*)$/ ) {
	    my @byeTeams = split /\s+/, $1;

	    foreach my $byeTeam (@byeTeams) {
		if ( ! defined($teamPlayed{$byeTeam}) ) {
		    print STDERR "team error: unknown team $byeTeam\n";
		    return 0;
		}
		$teamPlayed{$byeTeam} = 1;
	    }
	    $allResultsIn = 1;
	}
    }

    if ($allResultsIn) {
	# Fail a results file if not every tean is mentioned including
	# any BYES: teams. (but only if the round is complete.
	# A round is considered complente if there is a BYES: line at
	# the bottom. As I've mentioned elsewhere in comments across
	# the Perl code, I am a compulsive user of tipscore.pl and
	# ladder.pl, including during uncompleted rounds.


	foreach (keys %teamPlayed) {
	    if ( $teamPlayed{$_} == 0 ) {
		print STDERR "Error: team $_ not played in thisround!\n";
		return 0;
	    }
	}
    }

    return 1;
}
