GBASM=../gbasm

ASMFILES=$(wildcard *.asm)
EXPECTFILES=$(ASMFILES:%.asm=%.expect)
TESTFILES=$(ASMFILES:%.asm=%.gb)

test: $(TESTFILES)
	./runtests.sh

%.gb: %.asm %.expect $(GBASM)
	$(GBASM) -o $@ -m $<

clean:
	$(RM) *.gb
