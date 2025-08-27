#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/afl/lib";
use Test::More;
# Number of tests: 1 + number of fixtures files

use_ok('AFL');

my $fixturesdir = $AFL::GAMESDIR;
my $testsRun = 1;

opendir(my $fixturesdirfh, $fixturesdir)
    or die "Cannot open fixturesdir $fixturesdir: $!\n";

my (@fixturesfiles) = grep{ /\.txt$/ && -f "$fixturesdir/$_" } 
                        sort readdir ($fixturesdirfh);

foreach my $file (@fixturesfiles) {
    my $i = processFixturesFile($file);
    is($i, 1, "fixtures file $file clean");
    $testsRun++;
}

done_testing($testsRun);

sub processFixturesFile {
    my ($file) = @_;
    my @teams = @AFL::Teams;
    my %teamPlayed;
    foreach (@teams) {
	$teamPlayed{$_} = 0;
    }
    
    open(my $fh, '<', "$fixturesdir/$file")
	or die "cannot open $fixturesdir/$file: $!\n";
    while (my $line = <$fh>) {
	chomp($line);
	next if ( $line =~ /^#/ ); # column 1 comment line
	if ( $line =~ /^(\w+)\s+[vV]\s+(\w+)\s*$/ ) {
	    my ($homeTeam, $awayTeam) = ($1,$2);
	    if ( ! is_valid_team($homeTeam) ) {
	     	print STDERR "team error: unknown team $homeTeam\n";
                return 0;
	    }
	    if ( ! is_valid_team($awayTeam) ) {
                print STDERR "team error: unknown team $awayTeam\n";
                return 0;
	    }
	    # Special Round 24 had final GCT v ESS game which is the
	    # second game in Round24 for both teams. Allow this
	    # without the "team already played" error
	    if ( ( $file eq 'round24.txt') &&
		 ( $homeTeam eq 'GCT')     &&
		 ( $awayTeam eq 'ESS') ) {
		next;
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
	# if we reach here there is a bad line in the fixtures file
	print STDERR "Unknown fixtures file line: $line\n";
	return 0;
    }
    return 1;
}
