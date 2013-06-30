GBASM=../gbasm

ASMFILES=$(wildcard *.asm)
EXPECTFILES=$(ASMFILES:%.asm=%.expect)
TESTFILES=$(ASMFILES:%.asm=%.gb)

test: $(TESTFILES)
	./runtests.sh

%.gb: %.asm %.expect
	$(GBASM) -o $@ -m $<

clean:
	$(RM) *.gb
