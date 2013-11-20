#!/bin/bash

for x in *.asm; do
	diff -q "${x/.asm/.gb}" "${x/.asm/.expect}"
	if [ $? != 0 ]; then
		exit 1
	fi
done

echo "all files seem to be like expected"
exit 0
