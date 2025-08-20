package NRL;
use Exporter 'import';
@EXPORT = qw(is_valid_team);

# The 17 teams in the 2025 NRL competition, three letter abbreviations
@Teams = qw ( 
    AUK BRI BUL
    CAN CRO GCT
    MAN MEL NEW
    NQL PAR PEN
    RED ROO SOU
    STG WTI
    );

sub is_valid_team {
    # return 1 if the single argument is a valid team
    my ($team) = @_;
    return 0 if ( length($team) != 3 );
    foreach ( @Teams ) {
	return 1 if ( $_ eq $team );
    }
    # if we reach here we couldn't find a valid team in the @Teams array
    return 0;
}

$TEAMCOUNT = 17;

$RESULTSDIR = '/home/scooper/sports2025/nrl/results';
$GAMESDIR   = '/home/scooper/sports2025/nrl/fixtures';
$TIPSDIR    = '/home/scooper/sports2025/nrl/tips';

1;
