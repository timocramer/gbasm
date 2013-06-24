CFLAGS=-Wall -Wextra -O2 -pipe

HEADERS=gbasm.h gbparse.h buffer.h variables.h errors.h

.PHONY: all clean

all: gbasm gbdasm

gbasm: gbasm.o gbparse.o buffer.o lexer.o variables.o errors.o
	$(CC) -o $@ $^

gbdasm: gbdasm.o buffer.o errors.o
	$(CC) -o $@ $^

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

gbparse.c gbparse.h: gbparse.y
	bison -Wall -o gbparse.c -d $^

clean:
	$(RM) *.o gbparse.c gbparse.h gbasm gbdasm
