#include <string.h>
#define TEAMCOUNT 18 /* Number of teams in the competition */
#define RESULTSDIR "/home/scooper/sports2025/afl/results"
#define TIPSDIR    "/home/scooper/sports2025/afl/tips"
#define GAMESDIR   "/home/scooper/sports2025/afl/fixtures"

int is_valid_team(char *team);
int read_tipline(char *line, char *tippedToWin, char *tippedToLost);

/* static char *teams[] = { */
static char *teams[TEAMCOUNT] = {
  "ADE",
  "BRI",
  "CAR",
  "COL",
  "ESS",
  "FRE",
  "GEE",
  "GCT",
  "GWS",
  "HAW",
  "MEL",
  "NOR",
  "POR",
  "RIC",
  "STK",
  "SYD",
  "WBD",
  "WCT"  /* does this need a , at the end? I like one but I think */
	 /*  standards say no */

};





