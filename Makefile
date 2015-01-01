CFLAGS=-Wall -Wextra -O2 -pipe -std=c11 -D_POSIX_C_SOURCE=200809L

HEADERS=gbparse.h gbasm.h buffer.h variables.h errors.h

DESTDIR=/
PREFIX=/usr/local
BINDIR=$(DESTDIR)$(PREFIX)/bin

.PHONY: all clean install test

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
	@$(MAKE) -C test clean

test: gbasm
	@$(MAKE) -C test test

install:
	mkdir -p $(BINDIR)
	install -s gbasm $(BINDIR)
	install -s gbdasm $(BINDIR)
