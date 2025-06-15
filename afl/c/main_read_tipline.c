#include "AFL.h"
#include <stdio.h>

int main(int argc, char *argv[]) {
  char Team1[4], Team2[4];
  int i;

  i = read_tipline("STK d BRI", Team1, Team2);
  printf("read_tipline returns %d\n", i);
  if ( i == 1 ) {
    printf("%s tipped to beat %s\n", Team1, Team2);
  }
}
