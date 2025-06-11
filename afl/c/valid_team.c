#include "AFL.h"

// extern char *teams[18];

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
