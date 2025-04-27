#!/usr/bin/perl

use strict;
use warnings;

# FIXME: This script needs a lot of work but I'm sick of it being in
# the bin/ directory and not committed to the github project, so in it
# goes! The idea is you've tipped 6/6 going into Sunday and you're set
# for a big payout and you want to consider making "layoff" bets to
# lock in some profit. It would be heartbreaking to have eg
# a $6 makes $1987 bet lose when with some layoff bets you could lock
# in a $700 profit whatever happens. So triple_layoff.pl helps you do
# the maths for this kind of thing.

# changeable variables from current odds
my $ric_line_odds = 1.90;
my $stk_line_odds = 1.90;
my $haw_line_odds = 1.90;

# original 9 from 9 payout
my $jackpot = 1987;

# We can make up to three layoff bets.
# As soon as a layoff bet "wins", $jackpot is zero and you win
# whatever the layoff bet has won minus the amount you've spent
# on earlier layoff bets.
# Assume each of 3 layoff bets gets 1.90 odds
my ( $layoff1, $layoff2, $layoff3, $layoff_total );
my $layoff_spent = 0;
my $won = 0;

# print "Enter amounts for first/second/third layoff bets\n";
# my $line;
# $line = <STDIN>;
# chomp( $line );
# ($layoff1, $layoff2, $layoff3) = split /\s+/, $line;
($layoff1, $layoff2, $layoff3) = @ARGV;

# die "using layoff bets $layoff1 $layoff2 $layoff3\n";

# First game: WBD v GWS
$layoff_spent += $layoff1;
$won           = $layoff1 * $ric_line_odds - $layoff_spent;
$jackpot       = $jackpot - $layoff1;

print "layoff1 wins: $won loses: $jackpot still alive\n";

# Second game
$layoff_spent += $layoff2;
$won           = $layoff2 * $stk_line_odds - $layoff_spent;
$jackpot       = $jackpot - $layoff2;

print "layoff2 wins: $won loses: $jackpot still alive\n";

# Third and final game
$layoff_spent += $layoff3;
$won           = $layoff3 * $haw_line_odds - $layoff_spent;
$jackpot       = $jackpot - $layoff3;

print "layoff3 wins: $won loses: $jackpot COLLECT JACKPOT\n";
