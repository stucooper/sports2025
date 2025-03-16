#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/afl/lib";
use Test::More tests => 3;
# Number of tests: 1 + number of results files

use_ok('AFL');

my $resultsdir = $AFL::RESULTSDIR;

opendir(my $resultsdirfh, $resultsdir)
    or die "Cannot open resultsdir $resultsdir: $!\n";

my (@resultsfiles) = grep{ /\.txt$/ && -f "$resultsdir/$_" } 
                        readdir ($resultsdirfh);

foreach my $file (@resultsfiles) {
    my $i = processResultsFile($file);
    is($i, 1, "results file $file clean");
}

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
	}
    }
    return 1;
}
