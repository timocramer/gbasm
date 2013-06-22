#include <stdio.h>
#include <string.h>

#include "buffer.h"
#include "gbparse.h"
#include "variables.h"

char *src;
BUFFER *binary;

#define BUFSIZE 512
static char* read_file(FILE *f) {
	char tmp[BUFSIZE];
	size_t n;
	BUFFER *b = buffer_new();
	char *r;
	
	if(b == NULL)
		return NULL;
	
	do {
		n = fread(tmp, 1, BUFSIZE, f);
		buffer_add_mem(b, tmp, n);
	} while(n == BUFSIZE);
	
	if(ferror(f)) {
		puts("an error occured!");
		return NULL;
	}
	
	buffer_add_char(b, 0);
	r = b->data;
	buffer_destroy_keep(b);
	return r;
}

static void write_binary_to_file(const char *out_filename) {
	FILE *f;
	size_t written;
	
	f = fopen(out_filename, "w");
	if(f == NULL)
		return;
	
	written = fwrite(binary->data, 1, binary->size, f);
	if(written != binary->size)
		puts("binary was not written successfully");
	
	fclose(f);
}

int main(int argc, char **argv) {
	FILE *read_from_here;
	
	variables_init();
	
	binary = buffer_new();
	if(binary == NULL)
		return 1;
	
	if(argc < 2) {
		puts("error: please give filename");
		return 1;
	}
	
	read_from_here = fopen(argv[1], "r");
	if(read_from_here == NULL)
		return 1;
	
	src = read_file(read_from_here);
// 	puts(src);
	
	yyparse();
	
	write_binary_to_file("a.gb");
	
	return 0;
}
