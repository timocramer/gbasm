#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "errors.h"
#include "variables.h"

#ifdef DEBUG
#include <stdio.h>
#endif

struct variable {
	const char *name;
	unsigned int value;
};

#define ALLOC_CHUNK 64

static struct variable *vars;
static size_t vars_alloc;
static size_t vars_size;

static void resize_if_necessary(void) {
	struct variable *temp;
	
	if(vars_size >= vars_alloc) {
		vars_alloc += ALLOC_CHUNK;
		temp = realloc(vars, vars_alloc * sizeof(struct variable));
		if(temp == NULL)
			no_memory();
		vars = temp;
	}
}

void variables_init(void) {
	/* allocate the initial chunk */
	vars_size = 0;
	vars_alloc = 0;
	resize_if_necessary();
}

unsigned int* load_int(const char *name) {
	size_t i;
	
	for(i = 0; i < vars_size; ++i)
		if(strcmp(name, vars[i].name) == 0)
			return &(vars[i].value);
	return NULL;
}

int store_int(const char *name, unsigned int value) {
	size_t i;
	char *newname;
	
	for(i = 0; i < vars_size; ++i)
		if(strcmp(name, vars[i].name) == 0)
			return 1; /* multiple definition */
	resize_if_necessary();
	
	newname = strdup(name);
	if(newname == NULL)
		no_memory();
	
	vars[vars_size].value = value;
	vars[vars_size].name = newname;
	++vars_size;
	return 0;
}

#ifdef DEBUG
void variables_inspect(void) {
	size_t i;
	
	printf("===Variables===\nSize: %zu\nAllocated: %zu\n", vars_size, vars_alloc);
	for(i = 0; i < vars_size; ++i) {
		printf("Variable %zu:\n"
				"\tname: %s\n"
				"\tvalue %d\n",
				i,
				vars[i].name,
				vars[i].value);
	}
}
#endif
