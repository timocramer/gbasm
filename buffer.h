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

void buffer_add_char(BUFFER *, char);
void buffer_add_str(BUFFER *, const char *);
void buffer_add_mem(BUFFER *, const void *, size_t);

void buffer_add_u16l(BUFFER *, uint16_t);

void buffer_destroy(BUFFER *);
void buffer_destroy_keep(BUFFER *);

#endif
