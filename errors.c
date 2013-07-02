#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "gbparse.h"
#include "gbasm.h"
#include "errors.h"

void no_memory(void) {
	gbasm_error("not enough memory!");
}

void gbasm_error(const char *message, ...) {
	va_list args;
	
	fprintf(stderr, "%s: error: ", gbasm_filename);
	va_start(args, message);
	vfprintf(stderr, message, args);
	va_end(args);
	
	exit(1);
}

void gbasm_warning(const char *message, ...) {
	va_list args;
	
	fprintf(stderr, "%s: warning: ", gbasm_filename);
	va_start(args, message);
	vfprintf(stderr, message, args);
	va_end(args);
}

void location_error(YYLTYPE loc, char *message, ...) {
	va_list args;
	
	fprintf(stderr, "%s:%d:%d: error: ", input_filename, loc.first_line, loc.first_column);
	va_start(args, message);
	vfprintf(stderr, message, args);
	va_end(args);
	
	exit(1);
}

void location_warning(YYLTYPE loc, char *message, ...) {
	va_list args;
	
	fprintf(stderr, "%s:%d:%d: warning: ", input_filename, loc.first_line, loc.first_column);
	va_start(args, message);
	vfprintf(stderr, message, args);
	va_end(args);
}
