#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/afl/lib";
use Test::More;
# Number of tests: 1 + number of tips files

# This test is super-close to the 02_fixtures.t tests
# A valid fixture line is TEAM v TEAM
# A valid tip line is     TEAM d TEAM
# So the regular expression and the logic is almost identical

use_ok('AFL');

my $tipsdir = $AFL::TIPSDIR;
my $testsRun = 1;

opendir(my $tipsdirfh, $tipsdir)
    or die "Cannot open tipsdir $tipsdir: $!\n";

my (@tipsfiles) = grep{ /\.txt$/ && -f "$tipsdir/$_" } 
                        sort readdir ($tipsdirfh);

foreach my $file (@tipsfiles) {
    my $i = processTipsFile($file);
    is($i, 1, "tips file $file clean");
    $testsRun++;
}

done_testing($testsRun);

sub processTipsFile {
    my ($file) = @_;
    my @teams = @AFL::Teams;
    my %teamTipped;
    foreach (@teams) {
	$teamTipped{$_} = 0;
    }
    
    open(my $fh, '<', "$tipsdir/$file")
	or die "cannot open $tipsdir/$file: $!\n";
    while (my $line = <$fh>) {
	chomp($line);
	next if ( $line =~ /^#/ ); # column 1 comment line
	# TODO add support for the winning-margin tips line 
	if ( $line =~ /^(\w+)\s+d\s+(\w+)/ ) {
	    my ($homeTeam, $awayTeam) = ($1,$2);
	    if ( ! defined($teamTipped{$homeTeam}) ) {
	     	print STDERR "team error: unknown team $homeTeam\n";
                return 0;
	    }
	    if ( ! defined($teamTipped{$awayTeam}) ) {
                print STDERR "team error: unknown team $awayTeam\n";
                return 0;
	    }
	    if ( ( $teamTipped{$homeTeam} == 1 ) ) {
                print STDERR "team error: $homeTeam tipped twice??\n";
                return 0;
	    }
	    if ( ( $teamTipped{$awayTeam} == 1 ) ) {
                print STDERR "team error: $awayTeam tipped twice??\n";
                return 0;
	    }
	    $teamTipped{$homeTeam} = 1;
	    $teamTipped{$awayTeam} = 1;
	    next;
	}
	# if we reach here there is a bad line in the tips file
	print STDERR "Unknown tips file line: $line\n";
	return 0;
    }
    return 1;
}
