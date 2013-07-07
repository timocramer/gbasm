#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#include "buffer.h"
#include "gbparse.h"
#include "variables.h"
#include "errors.h"
#include "gbasm.h"


char *gbasm_filename;

char *input_filename;

char *src;
int pass;
BUFFER *binary;

static char* read_file(const char *filename) {
	FILE *f;
	char *r;
	long size;
	
	f = fopen(filename, "r");
	if(f == NULL)
		gbasm_error("'%s' cannot be opened: %s", filename, strerror(errno));
	
	if(fseek(f, 0, SEEK_END) != 0)
		goto error;
	
	size = ftell(f);
	if(size == -1)
		goto error;
	
	r = malloc(size + 1);
	if(r == NULL)
		no_memory();
	
	if((fseek(f, 0, SEEK_SET) != 0)
	|| (fread(r, size, 1, f) < 1)
	|| ferror(f))
		goto error;
	
	fclose(f);
	r[size] = 0;
	return r;
	
	error:
	gbasm_error("'%s' was not read successfully: %s", filename, strerror(errno));
	return NULL; /* so the compiler doesn't complain */
}

static char get_rom_size_code(size_t size) {
	char x = 0;
	size_t s = 32 * 1024;
	
	while(size > s) {
		s <<= 1;
		++x;
	}
	if(x > 6) /* largest known is 2 MB */
		gbasm_warning("The assembled binary is most certainly too large");
	return x;
}

static void warn_if_overwrite(void) {
	size_t i;
	for(i = 0x100; i < 0x150 && i < binary->size; ++i) {
		if(binary->data[i] != 0) {
			gbasm_warning("There is data that is overwritten by metadata");
			return;
		}
	}
}

#define GAME_NAME_MAX_LENGTH 15
#define GAME_NAME_OFFSET (4 + 48)
static void write_metadata(const char *game_name) {
	unsigned char complement;
	size_t i;
	char m[0x50] = {
		0, // nop
		0xc3, // jp
		0x50, 0x01, // 0x150
		// Nintendo-logo
0xCE,0xED,0x66,0x66,0xCC,0x0D,0x00,0x0B,0x03,0x73,0x00,0x83,0x00,0x0C,0x00,0x0D,
0x00,0x08,0x11,0x1F,0x88,0x89,0x00,0x0E,0xDC,0xCC,0x6E,0xE6,0xDD,0xDD,0xD9,0x99,
0xBB,0xBB,0x67,0x63,0x6E,0x0E,0xEC,0xCC,0xDD,0xDC,0x99,0x9F,0xBB,0xB9,0x33,0x3E,
		// 15 byte space for the name of the game
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, // no color GB
		0, 0, // Licensee code (usually ignored)
		0, // this is for Gameboy, not Super Gameboy
		0, // Cartridge Type: ROM Only
		0, // ROM Size: this value is set dynamically
		0, // RAM Size: 0
		1, // Destination Code: Non-Japanese
		0, // Licensee Code, I try it with a 0
		0, // Mask ROM Version number (Usually 0x00)
		0, // Complement check, this is set dynamically
		// (The sum of bytes 0x34 to 0x4d plus 25 has to be zero)
		0xC0,0x1A // Checksum (GameBoy ignores this value.)
	};
	
	strncpy(m + GAME_NAME_OFFSET, game_name, GAME_NAME_MAX_LENGTH);
	if(strlen(game_name) > GAME_NAME_MAX_LENGTH)
		gbasm_warning("Game name is too long and will be truncated");
	
	m[0x48] = get_rom_size_code(binary->size);
	
	/* don't ask. the GameBoy demands it */
	complement = 25;
	for(i = 0x34; i < 0x4d; ++i)
		complement += m[i];
	m[0x4d] = -complement;
	
	warn_if_overwrite();
	binary->write_pos = 0x100;
	buffer_add_mem(binary, m, 0x50);
}

static void write_binary_to_file(const char *out_filename) {
	FILE *f;
	size_t written;
	
	f = fopen(out_filename, "w");
	if(f == NULL)
		return;
	
	written = fwrite(binary->data, 1, binary->size, f);
	if(written != binary->size)
		gbasm_error("'%s' was not written successfully");
	
	fclose(f);
}


#define DEFAULT_OUTPUT_NAME "a.gb"
#define DEFAULT_GAME_NAME "THE GAME" /* you just lost it */

static void help(void) {
	fprintf(stderr, "Usage: %s [-n gamename] [-o output-file] [-m] input-file\n"
	"Options:\n"
	"  -n gamename     set the name that is written into the metadata (max. 15 byte, default: " DEFAULT_GAME_NAME ")\n"
	"  -o output-file  set the name of the file where the binary will be written to (default: " DEFAULT_OUTPUT_NAME ")\n"
	"  -m              don't write metadata automatically\n"
	"\n"
	"Example: %s -n \"MY GAME\" -o mygame.gb mygame.asm\n", gbasm_filename, gbasm_filename);
}

int main(int argc, char **argv) {
	int c;
	const char *output_name = DEFAULT_OUTPUT_NAME;
	const char *game_name = DEFAULT_GAME_NAME;
	int automatic_metadata = 1;
	char *srcbase;
	
	gbasm_filename = argv[0];
	
	while((c = getopt(argc, argv, "ho:n:m")) != -1) {
		switch(c) {
		case 'h':
			help();
			return 1;
		case 'o':
			output_name = optarg;
			break;
		case 'n':
			game_name = optarg;
			break;
		case 'm':
			automatic_metadata = 0;
			break;
		}
	}
	
	if(optind >= argc) {
		gbasm_error("no input files");
		return 1;
	}
	
	input_filename = argv[optind];
	
	src = read_file(input_filename);
	srcbase = src;
	
	variables_init();
	binary = buffer_new();
	
	pass = 1;
	yyparse();
	src = srcbase;
	yylloc.first_column = 0;
	yylloc.last_column = 0;
	yylloc.first_line = 0;
	yylloc.last_line = 0;
	binary->write_pos = 0;
	pass = 2;
	yyparse();
	
	if(automatic_metadata)
		write_metadata(game_name);
	write_binary_to_file(output_name);
	
	/* clean up a bit */
	free(srcbase);
	variables_destroy();
	buffer_destroy(binary);
	
	return 0;
}
