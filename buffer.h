#ifndef BUFFER_H
#define BUFFER_H

#include <stddef.h>
#include <stdint.h>

struct buffer {
	char *data;
	size_t size;
	size_t alloc_size;
	size_t write_pos;
};

void buffer_init(struct buffer *);

void buffer_add_char(struct buffer *, char);
void buffer_add_str(struct buffer *, const char *);
void buffer_add_mem(struct buffer *, const void *, size_t);

void buffer_add_u16l(struct buffer *, uint16_t);

#endif
