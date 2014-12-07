#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "errors.h"
#include "buffer.h"

struct buffer* buffer_new(void) {
	struct buffer *b;
	
	b = malloc(sizeof(struct buffer));
	if(b == NULL)
		no_memory();
	
	b->data = NULL;
	b->size = 0;
	b->alloc_size = 0;
	b->write_pos = 0;
	
	return b;
}

#define CHUNK_SIZE 128

static void buffer_resize(struct buffer *b, size_t size) {
	char *temp;
	
	temp = realloc(b->data, size);
	if(temp == NULL)
		no_memory();
	b->data = temp;
	b->alloc_size = size;
}

void buffer_add_char(struct buffer *b, char c) {
	size_t to_alloc;
	
	if(b == NULL)
		return;
	
	if(b->write_pos >= b->alloc_size) {
		to_alloc = CHUNK_SIZE * (b->write_pos / CHUNK_SIZE + 1);
		buffer_resize(b, to_alloc);
	}
	if(b->write_pos > b->size)
		memset(b->data + b->size, 0, b->write_pos - b->size);
	
	b->data[b->write_pos] = c;
	b->write_pos++;
	if(b->write_pos > b->size)
		b->size = b->write_pos;
}

/* adds a string but not the \0 at the end to the buffer */
void buffer_add_str(struct buffer *b, const char *s) {
	buffer_add_mem(b, s, strlen(s));
}

/* adds a chunk of memory with size s to the buffer */
void buffer_add_mem(struct buffer *b, const void *m, size_t s) {
	size_t total_maximum, to_alloc;
	
	if(b == NULL || m == NULL)
		return;
	
	total_maximum = b->write_pos + s;
	if(total_maximum >= b->alloc_size) {
		to_alloc = CHUNK_SIZE * (total_maximum / CHUNK_SIZE + 1);
		buffer_resize(b, to_alloc);
	}
	if(b->write_pos > b->size)
		memset(b->data + b->size, 0, b->write_pos - b->size);
	
	memcpy(b->data + b->write_pos, m, s);
	b->write_pos = total_maximum;
	if(total_maximum > b->size)
		b->size = total_maximum;
}

void buffer_add_u16l(struct buffer *b, uint16_t i) {
	buffer_add_char(b, i & 0xff);
	buffer_add_char(b, i >> 8);
}

/* frees the buffer and the internal data array */
void buffer_destroy(struct buffer *b) {
	if(b != NULL) {
		free(b->data);
		free(b);
	}
}

/* frees the buffer, but not the data component */
void buffer_destroy_keep(struct buffer *b) {
	free(b);
}
