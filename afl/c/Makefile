AFL: AFL.c AFL.h
	cc -o AFL AFL.c valid_team.o

valid_team.o: AFL.h valid_team.c
	cc -c valid_team.c

read_tipline.o: AFL.h read_tipline.c
	cc -c read_tipline.c

main_read_tipline: AFL.h read_tipline.o main_read_tipline.c
	cc -o main_read_tipline main_read_tipline.c read_tipline.o
