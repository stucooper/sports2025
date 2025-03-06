#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/afl/lib";
use Test::More tests => 3;

BEGIN {
  use_ok('AFL');
}

is(18, scalar(@AFL::Teams), '18 teams defined');
is($AFL::TEAMCOUNT, scalar(@AFL::Teams), '$TEAMCOUNT varaiable correct');

# check that every team eg WCT has a /teams/WCT.txt file
foreach my $team (@AFL::Teams) {
  if ( ! -f "/home/scooper/sports2025/afl/teams/$team.txt" ) {
     print "cannot find team file for $team\n";
  }
}

