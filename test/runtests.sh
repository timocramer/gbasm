#!/bin/bash

errors=0
for x in *.asm; do
	diff -q "${x/.asm/.gb}" "${x/.asm/.expect}"
	if [ $? != 0 ]; then
		errors=$((errors + 1))
	fi
done

echo "all tests done"
echo "errors: $errors"
if [ $errors = 0 ]; then
	exit 0
else
	exit 1
fi
