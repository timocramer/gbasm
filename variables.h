#ifndef VARIABLES_H
#define VARIABLES_H

#include <stdint.h>

void variables_init(void);

char* get_string(const char *);
unsigned int* get_int(const char *);

int set_string(const char *, char *);
int set_int(const char *, unsigned int);

#ifdef DEBUG
void variables_inspect(void);
#endif

#define set_int_var(var) set_int(#var, (var))
#define set_string_var(var) set_string(#var, (var))

#endif
