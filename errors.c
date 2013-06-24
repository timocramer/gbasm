#include <stdio.h>
#include <stdlib.h>

#include "gbasm.h"
#include "errors.h"

void no_memory(void) {
	gbasm_error("not enough memory!");
}

void gbasm_error(const char *message) {
	fprintf(stderr, "%s: error: %s\n", gbasm_filename, message);
	exit(1);
}
