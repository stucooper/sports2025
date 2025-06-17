#include "AFL.h"
#include <stdio.h>

int read_tipline(char *line, char *tippedToWin, char *tippedToLose) {
  /* Return: 0 if a comment line
             1 if a valid tip line
	    -1 if an invalid tip line
  */

  char toWin[4];  /* sscanf needs room for '\0' so [4] for a 3-wide teamname */
  char toLose[4];
  char isD;

  memset(toWin, 0, 3);
  memset(toLose, 0, 3);  
  
  if ( line[0] == '#' ) { return 0; }
  /* "GWS d BRI" */
  if ( strlen(line) != 9 ) { return -1; }
  if ( sscanf(line, "%s %c %s",toWin,&isD,toLose) != 3 ) { return -1; }
  /* TODO: allow for d or D in a tipline */
  if ( isD != 'd' ) { return -1; }
  strncpy(tippedToWin, toWin, 4);
  strncpy(tippedToLose, toLose, 4);  
  return 1;
}

