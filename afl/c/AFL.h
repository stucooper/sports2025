#include <string.h>
#define TEAMCOUNT 18 /* Number of teams in the competition */

char *teams[] = {
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
  "WCT",
  "WBD",
};

int is_valid_team (char *team) {
  int i,valid,len;
  
  len = strlen(team);
  if ( len != 3 ) {
    return(0);
  }
  for (i = 0; i < TEAMCOUNT; i++ ) {
    if (strcmp(team, teams[i]) == 0) {
      return(1);
    }
  }
  return(0);
}




