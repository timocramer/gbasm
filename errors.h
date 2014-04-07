#ifndef ERRORS_H
#define ERRORS_H

#include <stdarg.h>

#include "gbparse.h"

_Noreturn void no_memory(void);

_Noreturn void gbasm_error(const char *, ...);
void gbasm_warning(const char *, ...);

_Noreturn void location_error(YYLTYPE, char *, ...);
void location_warning(YYLTYPE, char *, ...);
#endif
