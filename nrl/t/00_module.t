#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/nrl/lib";
use Test::More tests => 3;

use_ok('NRL');

is(17, scalar(@NRL::Teams), '17 teams defined');
is($NRL::TEAMCOUNT, scalar(@NRL::Teams), '$TEAMCOUNT varaiable correct');

