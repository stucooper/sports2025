#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/afl/lib";
# use Test::More tests => 4;
use Test::More;
# Number of tests: 1 + number of results files

use_ok('AFL');

my $resultsdir = $AFL::RESULTSDIR;
my $testsRun = 1;

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
    my @teams = @AFL::Teams;
    my %teamPlayed;
    foreach (@teams) {
	$teamPlayed{$_} = 0;
    }
    
    open(my $fh, '<', "$resultsdir/$file")
	or die "cannot open $resultsdir/$file: $!\n";
    while (my $line = <$fh>) {
	chomp($line);
	next if ( $line =~ /^#/ ); # column 1 comment line
	if ( $line =~ /(\d{8})\s+(\w+)\s+\d+\s+(\w+)\s+\d+/ ) {
	    my ($matchDate, $homeTeam, $awayTeam) = ($1,$2,$3);
	    if ($matchDate < $date) {
		print STDERR "date error $matchDate earlier than $date\n";
                return 0;
	    }
	    $date = $matchDate;
	    if ( ! is_valid_team($homeTeam) ) {
	     	print STDERR "team error: unknown team $homeTeam\n";
                return 0;
	    }
	    if ( ! is_valid_team($awayTeam) ) {
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
	    next;
	}
	# if we reach here there is a bad line in the results file
	print STDERR "Unknown results file line: $line\n";
	return 0;
    }
    return 1;
}
