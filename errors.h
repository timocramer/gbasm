#ifndef ERRORS_H
#define ERRORS_H

#include <stdarg.h>

#include "gbparse.h"

void no_memory(void);

void gbasm_error(const char *, ...);
void gbasm_warning(const char *, ...);

void location_error(YYLTYPE, char *, ...);
void location_warning(YYLTYPE, char *, ...);
#endif
