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

void gbasm_warning(const char *message) {
	fprintf(stderr, "%s: warning: %s\n", gbasm_filename, message);
}

void location_error(int line, int column, char *message) {
	fprintf(stderr, "%s:%d:%d: error: %s\n", input_filename, line, column, message);
	exit(1);
}
