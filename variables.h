#ifndef VARIABLES_H
#define VARIABLES_H

#include <stdint.h>

void variables_init(void);
void variables_destroy(void);

unsigned int* load_int(const char *);

int store_label(const char *, unsigned int);
int store_int(const char *, unsigned int);

#ifdef DEBUG
void variables_inspect(void);
#endif

#endif
