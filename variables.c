#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "errors.h"
#include "variables.h"

#ifdef DEBUG
#include <stdio.h>
#endif

enum vartype {INT, STRING};

union value {
	unsigned int i;
	char *s;
};

struct variable {
	enum vartype type;
	const char *name;
	union value value;
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


char* get_string(const char *name) {
	size_t i;
	
	for(i = 0; i < vars_size; ++i)
		if((vars[i].type == STRING) && (strcmp(name, vars[i].name) == 0))
			return vars[i].value.s;
	return NULL;
}

unsigned int* get_int(const char *name) {
	size_t i;
	
	for(i = 0; i < vars_size; ++i)
		if((vars[i].type == INT) && (strcmp(name, vars[i].name) == 0))
			return &(vars[i].value.i);
	return NULL;
}


static int set_generic(const char *name, enum vartype type, union value value) {
	size_t i;
	
	for(i = 0; i < vars_size; ++i)
		if(strcmp(name, vars[i].name) == 0)
			return 1; /* multiple definition */
	resize_if_necessary();
	vars[vars_size].value = value;
	vars[vars_size].type = type;
	vars[vars_size].name = name;
	++vars_size;
	return 0;
}

int set_string(const char *name, char *str) {
	union value value = {.s = str};
	
	return set_generic(name, STRING, value);
}

int set_int(const char *name, unsigned int val) {
	union value value = {.i = val};
	
	return set_generic(name, INT, value);
}

#ifdef DEBUG
void variables_inspect(void) {
	size_t i;
	
	printf("===Variables===\nSize: %zu\nAllocated: %zu\n", vars_size, vars_alloc);
	for(i = 0; i < vars_size; ++i) {
		if(vars[i].type == INT) {
			printf("Variable %zu:\n"
					"\ttype: INT\n"
					"\tname: %s\n"
					"\tvalue %d\n",
					i,
					vars[i].name,
					vars[i].value.i);
		}
		else {
			printf("Variable %zu:\n"
					"\ttype: STRING\n"
					"\tname: %s\n"
					"\tvalue %s\n",
					i,
					vars[i].name,
					vars[i].value.s);
		}
	}
}
#endif
