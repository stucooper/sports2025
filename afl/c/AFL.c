#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>

#include "AFL.h"

int main (int argc, char *argv[]) {
  int i;
  DIR *dirfh;

  i = TEAMCOUNT;
  printf("There are %d teams in the AFL\n", i);
  i = is_valid_team("FREM");
  printf("is FREM valid?: %d\n", i);
  i = is_valid_team("CAR");
  printf("is CAR valid?: %d\n", i);
  i = is_valid_team("XYZ");
  printf("is XYZ valid?: %d\n", i);

  /* check the directories can be opened */
  dirfh = opendir(RESULTSDIR);
  if ( dirfh == (DIR *)NULL) {
    printf("Cannot open directory %s\n", RESULTSDIR);
  }

  dirfh = opendir(TIPSDIR);
  if ( dirfh == (DIR *)NULL) {
    printf("Cannot open directory %s\n", TIPSDIR);
  }

  dirfh = opendir(GAMESDIR);
  if ( dirfh == (DIR *)NULL) {
    printf("Cannot open directory %s\n", GAMESDIR);
  }

  dirfh = opendir("/directory/not/there");
  if ( dirfh == (DIR *)NULL) {
    printf("Cannot open directory %s\n", "/directory/not/there");
  }

  return(0);
}
