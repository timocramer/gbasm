#!/bin/bash

for x in *.asm; do
	diff -q "${x/.asm/.gb}" "${x/.asm/.expect}"
done

exit 0
