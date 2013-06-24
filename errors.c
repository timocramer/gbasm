#include <stdio.h>
#include <stdlib.h>

#include "gbasm.h"
#include "errors.h"

void no_memory(void) {
	fprintf(stderr, "%s: not enough memory!\n", gbasm_filename);
	exit(1);
}
