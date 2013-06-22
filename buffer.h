#ifndef BUFFER_H
#define BUFFER_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
	char *data;
	size_t size;
	size_t alloc_size;
	size_t write_pos;
} BUFFER;

BUFFER* buffer_new(void);

int buffer_add_char(BUFFER *, char);
int buffer_add_str(BUFFER *, const char *);
int buffer_add_mem(BUFFER *, const void *, size_t);

int buffer_add_u16l(BUFFER *, uint16_t);

void buffer_destroy(BUFFER *);
void buffer_destroy_keep(BUFFER *);

void buffer_reset(BUFFER *);

#endif
