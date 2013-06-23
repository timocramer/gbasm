CFLAGS=-Wall -Wextra -O2 -pipe

SOURCES=gbasm.c gbparse.c buffer.c lexer.c variables.c
OBJECTS=$(SOURCES:%.c=%.o)
HEADERS=gbparse.h buffer.h variables.h

.PHONY: clean

gbasm: $(OBJECTS)
	$(CC) -o $@ $^

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

gbparse.c gbparse.h: gbparse.y
	bison -Wall -o gbparse.c -d $^

clean:
	$(RM) *.o gbparse.c gbparse.h gbasm
