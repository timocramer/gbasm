#ifndef ERRORS_H
#define ERRORS_H

#include <stdarg.h>

#include "gbparse.h"

#ifndef __GNUC__
#undef __attribute__
#define __attribute__(xyz)
#endif

void no_memory(void) __attribute__((noreturn));

void gbasm_error(const char *, ...) __attribute__((noreturn));
void gbasm_warning(const char *, ...);

void location_error(YYLTYPE, char *, ...) __attribute__((noreturn));
void location_warning(YYLTYPE, char *, ...);
#endif
