package AFL;
use Exporter 'import';
@EXPORT = qw(is_valid_team);

# The 18 teams in the 2025 AFL competition, three letter abbreviations
@Teams = qw ( 
    ADE BRI CAR
    COL ESS FRE
    GEE GCT GWS
    HAW MEL NOR
    POR RIC STK
    SYD WBD WCT
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

$TEAMCOUNT = 18;

$RESULTSDIR = '/home/scooper/sports2025/afl/results';
$TIPSDIR    = '/home/scooper/sports2025/afl/tips';
$GAMESDIR   = '/home/scooper/sports2025/afl/fixtures';
1;
