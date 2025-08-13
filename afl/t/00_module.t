#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/afl/lib";
use Test::More tests => 12;

BEGIN {
    use_ok('AFL');
}
can_ok('AFL', 'is_valid_team');

is(0, is_valid_team('WCE'), 'WCE not valid team');   # bad name I use WCT
is(0, is_valid_team('COLL'), 'COLL not valid team'); # COL
is(1, is_valid_team('WBD'), 'WBD is a valid team');

is(18, scalar(@AFL::Teams), '18 teams defined');
is($AFL::TEAMCOUNT, scalar(@AFL::Teams), '$TEAMCOUNT varaiable correct');

# Test 4: check that there are $TEAMCOUNT *.txt files in teams
my $teamsdir = "/home/scooper/sports2025/afl/teams";
opendir(my $teamsdirfh, $teamsdir);
my (@teamfiles) = grep{ /\.txt$/ && -f "$teamsdir/$_" } readdir ($teamsdirfh);
is($AFL::TEAMCOUNT, scalar(@teamfiles), "$AFL::TEAMCOUNT .txt files found");

# Test 5: check that each team eg WCT has a /teams/WCT.txt file
my $all_teams_present = 1;

foreach my $team (@AFL::Teams) {
  if ( ! -f "/home/scooper/sports2025/afl/teams/$team.txt" ) {
     diag "missing team file for $team\n";
     $all_teams_present = 0;
  }
}
is($all_teams_present, 1, "All teams have a .txt file");

my $direxists = 0;
if ( -d $AFL::RESULTSDIR ) {
    $direxists = 1;
}
is($direxists, 1, '$AFL::RESULTSDIR exists');

$direxists = 0;
if ( -d $AFL::TIPSDIR ) {
    $direxists = 1;
}
is($direxists, 1, '$AFL::TIPSDIR exists');

$direxists = 0;
if ( -d $AFL::GAMESDIR ) {
    $direxists = 1;
}
is($direxists, 1, '$AFL::GAMESDIR exists');
