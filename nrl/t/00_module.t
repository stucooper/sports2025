#!/usr/bin/perl
use strict;
use lib "/home/scooper/sports2025/nrl/lib";
use Test::More tests => 7;

use_ok('NRL');
can_ok('NRL', 'is_valid_team');

is(0, is_valid_team('PAN'), 'PAN not valid team');   # bad name I use PEN
is(0, is_valid_team('PARR'), 'PARR not valid team'); # PAR not PARR
is(1, is_valid_team('AUK'), 'AUK is a valid team');

is(17, scalar(@NRL::Teams), '17 teams defined');
is($NRL::TEAMCOUNT, scalar(@NRL::Teams), '$TEAMCOUNT varaiable correct');

