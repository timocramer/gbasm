#ifndef VARIABLES_H
#define VARIABLES_H

#include <stdint.h>

void variables_init(void);

unsigned int* get_int(const char *);

int set_int(const char *, unsigned int);

#ifdef DEBUG
void variables_inspect(void);
#endif

#endif
