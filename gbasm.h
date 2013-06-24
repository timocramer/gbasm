#ifndef GBASM_H
#define GBASM_H

#include "buffer.h"

extern char *gbasm_filename;

/* src is the pointer in the sourcefile, used by yylex */
extern char *src;

extern BUFFER *binary;

#endif
