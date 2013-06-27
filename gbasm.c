#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "buffer.h"
#include "gbparse.h"
#include "variables.h"
#include "errors.h"
#include "gbasm.h"


char *gbasm_filename;

char *src;
BUFFER *binary;

#define BUFSIZE 512
static char* read_file(const char *input_filename) {
	FILE *f;
	char tmp[BUFSIZE];
	size_t n;
	BUFFER *b = buffer_new();
	char *r;
	
	f = fopen(input_filename, "r");
	if(f == NULL) {
		fprintf(stderr, "%s: '%s' cannot be opened\n", gbasm_filename, input_filename);
		return NULL;
	}
	
	do {
		n = fread(tmp, 1, BUFSIZE, f);
		buffer_add_mem(b, tmp, n);
	} while(n == BUFSIZE);
	
	if(ferror(f)) {
		fprintf(stderr, "%s: an error occured reading '%s'!\n", gbasm_filename, input_filename);
		return NULL;
	}
	fclose(f);
	
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
		gbasm_error("binary was not written successfully");
	
	fclose(f);
}

int main(int argc, char **argv) {
	char *srcbase;
	
	gbasm_filename = argv[0];
	
	variables_init();
	
	binary = buffer_new();
	
	if(argc < 2) {
		gbasm_error("no input files");
		return 1;
	}
	
	src = read_file(argv[1]);
	if(src == NULL)
		return 1;
	srcbase = src;
	
	yyparse();
	
	
	write_binary_to_file("a.gb");
	
	/* clean up a bit */
	free(srcbase);
	variables_destroy();
	buffer_destroy(binary);
	
	return 0;
}
