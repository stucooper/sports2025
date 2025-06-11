#include <stdio.h>
#include "AFL.h"

int main (int argc, char *argv[]) {
  int i;
  i = TEAMCOUNT;
  printf("There are %d teams in the AFL\n", i);
  for ( i = 0; i < TEAMCOUNT; i++ ) {
    printf("Team %2d is %s\n", i, teams[i]);
  }
  i = is_valid_team("FREM");
  printf("is FREM valid?: %d\n", i);
  i = is_valid_team("CAR");
  printf("is CAR valid?: %d\n", i);
  i = is_valid_team("XYZ");
  printf("is XYZ valid?: %d\n", i);
}
