CFLAGS=-Wall -Wextra -O2 -pipe

HEADERS=gbparse.h gbasm.h buffer.h variables.h errors.h

PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

.PHONY: all clean install

all: gbasm gbdasm

gbasm: gbparse.o gbasm.o buffer.o lexer.o variables.o errors.o
	$(CC) -o $@ $^

gbdasm: gbdasm.o errors.o
	$(CC) -o $@ $^

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

%.h %.c: %.y
	bison -Wall -o $*.c --defines=$*.h $^

clean:
	$(RM) *.o gbparse.c gbparse.h gbasm gbdasm

install:
	install -Ds gbasm $(BINDIR)
	install -Ds gbdasm $(BINDIR)
