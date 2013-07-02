#ifndef ERRORS_H
#define ERRORS_H

#include <stdarg.h>

void no_memory(void);

void gbasm_error(const char *, ...);
void gbasm_warning(const char *, ...);

void location_error(int, int, char *, ...);
void location_warning(int, int, char *, ...);
#endif
