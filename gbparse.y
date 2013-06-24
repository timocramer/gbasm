%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>

#include "buffer.h"
#include "variables.h"
#include "gbparse.h"

extern int yylex(void);
static void yyerror(char const *);

static char* concat_strings(char *, char *);

extern BUFFER *binary;
static BUFFER *tmpbuf;

#define DEFINE_GET_UINT(bit) \
static uint##bit##_t get_uint##bit(unsigned int t) {\
	const uint##bit##_t i = t;\
	const int##bit##_t j = t;\
	if(i != t && j != (signed int)t)\
		printf("integer is bigger than " #bit " bit and will be truncated\n");\
	return i;\
}

DEFINE_GET_UINT(8)
DEFINE_GET_UINT(16)

#define SREG(x) (\
	((x) == 0) ? "b" :\
	((x) == 1) ? "c" :\
	((x) == 2) ? "d" :\
	((x) == 3) ? "e" :\
	((x) == 4) ? "h" :\
	((x) == 5) ? "l" :\
	((x) == 6) ? "[hl]" :\
	((x) == 7) ? "a" :\
	"error"\
)

#define ALUOP(x) (\
	((x) == 0) ? "add" :\
	((x) == 1) ? "adc" :\
	((x) == 2) ? "sub" :\
	((x) == 3) ? "sbc" :\
	((x) == 4) ? "and" :\
	((x) == 5) ? "xor" :\
	((x) == 6) ? "or" :\
	((x) == 7) ? "cp" :\
	"error"\
)

#define ALUDREG(x) (\
	((x) == 0) ? "bc" :\
	((x) == 1) ? "de" :\
	((x) == 2) ? "hl" :\
	((x) == 3) ? "sp" :\
	"error"\
)

#define PPDREG(x) (\
	((x) == 0) ? "bc" :\
	((x) == 1) ? "de" :\
	((x) == 2) ? "hl" :\
	((x) == 3) ? "af" :\
	"error"\
)

#define FLAG(x) (\
	((x) == 0) ? "nz" :\
	((x) == 1) ? "z" :\
	((x) == 2) ? "nc" :\
	((x) == 3) ? "x" :\
	"error"\
)

#define CB_FUNC(x) (\
	((x) == 0) ? "rlc" :\
	((x) == 1) ? "rrc" :\
	((x) == 2) ? "rl" :\
	((x) == 3) ? "rr" :\
	((x) == 4) ? "sla" :\
	((x) == 5) ? "sra" :\
	((x) == 6) ? "swap" :\
	((x) == 7) ? "srl" :\
	"error"\
)

#define CB_INT_FUNC(x) (\
	((x) == 1) ? "bit" :\
	((x) == 2) ? "res" :\
	((x) == 3) ? "set" :\
	"error"\
)

#define SINGLE_INSTRUCTION(x) (\
	((x) == 0x00) ? "nop" :\
	((x) == 0x3f) ? "ccf" :\
	((x) == 0x2f) ? "cpl" :\
	((x) == 0x27) ? "daa" :\
	((x) == 0xf3) ? "di" :\
	((x) == 0xfb) ? "ei" :\
	((x) == 0x76) ? "halt" :\
	((x) == 0xc9) ? "ret" :\
	((x) == 0xd9) ? "reti" :\
	((x) == 0x17) ? "rla" :\
	((x) == 0x07) ? "rlca" :\
	((x) == 0x1f) ? "rra" :\
	((x) == 0x0f) ? "rrca" :\
	((x) == 0x37) ? "scf" :\
	((x) == 0x10) ? "stop" :\
	"error"\
)

#ifdef DEBUG
#define debug_puts(s) puts(s)
#else
#define debug_puts(s) (void) s
#endif

#define INCREMENT 0
#define DECREMENT 1

#define MEMORY_TO_REGISTER 1
#define REGISTER_TO_MEMORY 0

#define HAS_FLAG 1
#define NO_FLAG 0

static void define_const(const char *, unsigned int);
static void ds(unsigned int, unsigned char);
static void write_bytes(const char *, size_t);

static void jp(int, unsigned char, uint16_t);
static void jr(int, unsigned char, unsigned char);
static void call(int, unsigned char, uint16_t);

static void ret(unsigned char);

static void ld_simple(unsigned char, unsigned char);
static void ld_const(unsigned char, unsigned char);
static void ld_bcde(unsigned char, unsigned char);
static void ld_a_mem(unsigned char, uint16_t);

static void ldi_ldd(unsigned char, unsigned char);

static void ldh_addr(unsigned char, unsigned char);
static void ldh_c(unsigned char);

static void ld_const16(unsigned char, uint16_t);
static void ldhl(unsigned char);
static void ld_sp_mem(uint16_t);

static void inc_dec_dreg(unsigned char, unsigned char);
static void inc_dec_sreg(unsigned char, unsigned char);

static void aluop_simple(unsigned char, unsigned char);
static void aluop_const(unsigned char, unsigned char);

static void add_hl(unsigned char);
static void add_sp(unsigned char);

static void push_pop(unsigned char, unsigned char);

static void rst(unsigned int);

static void cb_function(unsigned char, unsigned char);
static void cb_int_function(unsigned char, unsigned int, unsigned char);
%}

%initial-action {
	tmpbuf = buffer_new();
}

%union {
	char *string;
	unsigned int integer;
	char *identifier;
	unsigned char intern;
}

%token <integer> NUM
%token <string> STR
%token <identifier> IDENT

%type <intern> pushpopdreg aluoperation aludreg aludreg_without_sp singlereg singlereg_without_a flag cb_with_int cb_without_int single_instruction bcde

%type <integer> numexp uint16list uint16 uint8 uint8list

%type <string> string stringlist

%token DB DEFB DM DEFM DS DEFS DW DEFW SEEK INC DEC JR LDD LDI PUSH POP CALL JP RET LDHL RST LDH LD RLC RRC RL RR SLA SRA SWAP SRL BIT RES SET CCF CPL DAA DI EI HALT NOP RETI RLA RLCA RRA RRCA SCF STOP Z NZ NC A B C D E H L ADD ADC SUB SBC AND OR XOR CP BC DE HL AF SP DEFINE

%left ','

%right '?' ':'
%left LOGOR
%left LOGAND
%left '|'
%left '^'
%left '&'
%nonassoc EQ NEQ
%nonassoc '<' LE '>' GE
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%'
%left UNARY

%% /* Grammar rules and actions follow. */

commands:
/* empty */
| commands command
;

command:
/** commands to the assembler */
/* label definition */
IDENT ':' { define_const($1, binary->write_pos); }
/* constant definition */
| '#' DEFINE IDENT numexp { define_const($3, $4); }

| DM stringlist {
		write_bytes($2, strlen($2));
		free($2);
	}
| DB uint8list {
		write_bytes(tmpbuf->data, tmpbuf->size);
		buffer_reset(tmpbuf);
	}
| DW uint16list {
		write_bytes(tmpbuf->data, tmpbuf->size);
		buffer_reset(tmpbuf);
	}
| DS numexp { ds($2, 0); }
| DS numexp ',' uint8 { ds($2, $4); }
| SEEK numexp {
	#ifdef DEBUG
		printf("seek %d\n", $2);
	#endif
		binary->write_pos = $2;
	}

/** real instructions */
/* instructions without arguments */
| single_instruction {
		debug_puts(SINGLE_INSTRUCTION($1));
		buffer_add_char(binary, $1);
	}

/* push & pop */
| PUSH pushpopdreg { push_pop(DECREMENT, $2); }
| POP pushpopdreg { push_pop(INCREMENT, $2); }

/* 8-bit ALU operations */
| aluoperation singlereg { aluop_simple($1, $2); }
| aluoperation uint8 { aluop_const($1, $2); }
/* some instructions are documented with an A and a comma, you can use both */
| aluoperation A ',' singlereg { aluop_simple($1, $4); }
| aluoperation A ',' uint8 { aluop_const($1, $4); }

/* 16 bit add */
| ADD HL ',' aludreg { add_hl($4); }
| ADD SP ',' uint8 { add_sp($4); }

/* increment & decrement */
| INC singlereg { inc_dec_sreg(INCREMENT, $2); }
| DEC singlereg { inc_dec_sreg(DECREMENT, $2); }

| INC aludreg { inc_dec_dreg(INCREMENT, $2); }
| DEC aludreg { inc_dec_dreg(DECREMENT, $2); }

/* jumps */
| JP uint16 { jp(NO_FLAG, 0, $2); }
| JP flag ',' uint16 { jp(HAS_FLAG, $2, $4); }
| JP HL {
		debug_puts("jp hl");
		buffer_add_char(binary, 0xe9);
	}

| JR uint8 { jr(NO_FLAG, 0, $2); }
| JR flag ',' uint8 { jr(HAS_FLAG, $2, $4); }

| CALL uint16 { call(NO_FLAG, 0, $2); }
| CALL flag ',' uint16 { call(HAS_FLAG, $2, $4); }

/* 8-bit load */
| LD singlereg_without_a ',' singlereg { ld_simple($2, $4); }
| LD A ',' singlereg { ld_simple(7, $4); }

| LD singlereg_without_a ',' uint8 { ld_const($2, $4); }
| LD A ',' uint8 { ld_const(7, $4); }
/* we have to make a special sausage for A, because of a shift/reduce conflict */

| LD A ',' '[' uint16 ']' { ld_a_mem(MEMORY_TO_REGISTER, $5); }
| LD '[' uint16 ']' ',' A { ld_a_mem(REGISTER_TO_MEMORY, $3); }

| LD '[' bcde ']' ',' A { ld_bcde($3, REGISTER_TO_MEMORY); }
| LD A ',' '[' bcde ']' { ld_bcde($5, MEMORY_TO_REGISTER); }

| LDI '[' HL ']' ',' A { ldi_ldd(INCREMENT, REGISTER_TO_MEMORY); }
| LDI A ',' '[' HL ']' { ldi_ldd(INCREMENT, MEMORY_TO_REGISTER); }

| LDD '[' HL ']' ',' A { ldi_ldd(DECREMENT, REGISTER_TO_MEMORY); }
| LDD A ',' '[' HL ']' { ldi_ldd(DECREMENT, MEMORY_TO_REGISTER); }

| LDH '[' uint8 ']' ',' A { ldh_addr(REGISTER_TO_MEMORY, $3); }
| LDH A ',' '[' uint8 ']' { ldh_addr(MEMORY_TO_REGISTER, $5); }

| LDH '[' C ']' ',' A { ldh_c(REGISTER_TO_MEMORY); }
| LDH A ',' '[' C ']' { ldh_c(MEMORY_TO_REGISTER); }

/* 16 bit loads */
| LD aludreg_without_sp ',' uint16 { ld_const16($2, $4); }
| LD SP ',' uint16 { ld_const16(3, $4); }
/* also we have to make a special sausage for SP, because of a shift/reduce conflict */

| LD '[' uint16 ']' ',' SP { ld_sp_mem($3); }
| LD SP ',' HL {
		debug_puts("ld sp, hl");
		buffer_add_char(binary, 0xf9);
	}
| LDHL SP ',' uint8 { ldhl($4); }

| RET flag { ret($2); }

| RST numexp { rst($2); }

/* bitwise functions with cb prefix */
| cb_without_int singlereg { cb_function($1, $2); }

| cb_with_int numexp ',' singlereg {
		if($2 >= 8) { /* because */
			fprintf(stderr, "%d:%d: the bit index has to be between 0 and 7\n",
				@2.first_line, @2.first_column);
			exit(1);
		}
		cb_int_function($1, $2, $4);
	}
;

cb_without_int:
RLC { $$ = 0; }
| RRC { $$ = 1; }
| RL { $$ = 2; }
| RR { $$ = 3; }
| SLA { $$ = 4; }
| SRA { $$ = 5; }
| SWAP { $$ = 6; }
| SRL { $$ = 7; }
;
cb_with_int:
BIT { $$ = 1; }
| RES { $$ = 2; }
| SET { $$ = 3; }
;

single_instruction:
NOP { $$ = 0x00; }
| CCF { $$ = 0x3f; }
| CPL { $$ = 0x2f; }
| DAA { $$ = 0x27; }
| DI { $$ = 0xf3; }
| EI { $$ = 0xfb; }
| HALT { $$ = 0x76; }
| RET { $$ = 0xc9; }
| RETI { $$ = 0xd9; }
| RLA { $$ = 0x17; }
| RLCA { $$ = 0x07; }
| RRA { $$ = 0x1f; }
| RRCA { $$ = 0x0f; }
| SCF { $$ = 0x37; }
| STOP { $$ = 0x10; }
;


singlereg_without_a:
B { $$ = 0; }
| C { $$ = 1; }
| D { $$ = 2; }
| E { $$ = 3; }
| H { $$ = 4; }
| L { $$ = 5; }
| '[' HL ']' { $$ = 6; }
;
singlereg:
singlereg_without_a
| A { $$ = 7; }
;

aluoperation:
ADD { $$ = 0; }
| ADC { $$ = 1; }
| SUB { $$ = 2; }
| SBC { $$ = 3; }
| AND { $$ = 4; }
| XOR { $$ = 5; }
| OR { $$ = 6; }
| CP { $$ = 7; }
;

bcde: BC { $$ = 0; } | DE { $$ = 1; };
aludreg_without_sp: bcde | HL { $$ = 2; };
aludreg:     aludreg_without_sp | SP { $$ = 3; };
pushpopdreg: aludreg_without_sp | AF { $$ = 3; };

flag:
NZ { $$ = 0; }
| Z { $$ = 1; }
| NC { $$ = 2; }
| C { $$ = 3; }
;

uint8: numexp { $$ = get_uint8($1); };
uint16: numexp { $$ = get_uint16($1); };

numexp:
NUM { $$ = $1; }
| IDENT {
		unsigned int *p = get_int($1);
		if(p == NULL)
			yyerror("unknown variable");
		$$ = *p;
	}

| '-' numexp %prec UNARY { $$ = -$2; } /* unary minus */
| '+' numexp %prec UNARY { $$ = +$2; } /* unary plus */
| '!' numexp %prec UNARY { $$ = !$2; } /* logical negation */
| '~' numexp %prec UNARY { $$ = ~$2; } /* bitwise negation */

| numexp '+' numexp { $$ = $1 + $3; }
| numexp '-' numexp { $$ = $1 - $3; }

| numexp '*' numexp { $$ = $1 * $3; }
| numexp '/' numexp { $$ = $1 / $3; }
| numexp '%' numexp { $$ = $1 % $3; }

| numexp LSHIFT numexp { $$ = $1 << $3; }
| numexp RSHIFT numexp { $$ = $1 >> $3; }

| numexp '<' numexp { $$ = $1 < $3; }
| numexp LE numexp  { $$ = $1 <= $3; }
| numexp '>' numexp { $$ = $1 > $3; }
| numexp GE numexp  { $$ = $1 >= $3; }

| numexp EQ numexp  { $$ = $1 == $3; }
| numexp NEQ numexp { $$ = $1 != $3; }

| numexp '&' numexp { $$ = $1 & $3; }
| numexp '|' numexp { $$ = $1 | $3; }
| numexp '^' numexp { $$ = $1 ^ $3; }

| numexp LOGAND numexp { $$ = $1 && $3; }
| numexp LOGOR numexp  { $$ = $1 || $3; }

| numexp '?' numexp ':' numexp { $$ = $1 ? $3 : $5; }

| '(' numexp ')' { $$ = $2; }
;

string:
STR { $$ = $1; }
| string STR { $$ = concat_strings($1, $2); }
/*
The following two rules work, but only when "string STR" is disabled.
Also error messages give false positions when they are enabled and a
numexp is given when a string is expected.
| string '+' string { $$ = concat_strings($1, $3); }
| numexp '?' string ':' string { $$ = $1 ? $3 : $5; }
*/
;

uint8list:
uint8 { buffer_add_char(tmpbuf, $1); }
| uint8list ',' uint8 { buffer_add_char(tmpbuf, $3); }
;

uint16list:
uint16 { buffer_add_u16l(tmpbuf, $1); }
| uint16list ',' uint16 { buffer_add_u16l(tmpbuf, $3); }
;

stringlist:
string { $$ = $1; }
| stringlist ',' string { $$ = concat_strings($1, $3); }
;

%%

static void yyerror(char const *s) {
	fprintf(stderr, "%d:%d: %s\n", yylloc.first_line, yylloc.first_column, s);
	exit(1);
}

static void define_const(const char *name, unsigned int x) {
#ifdef DEBUG
	printf("#define %s %u\n", name, x);
#endif
	set_int(name, x);
	/* TODO: error handling */
}

static char* concat_strings(char *a, char *b) {
	char *t = realloc(a, strlen(a) + strlen(b) + 1);
	
	if(t == NULL)
		{}; /* error */
	
	strcat(t, b);
	free(b);
	return t;
}

static void ds(unsigned int size, unsigned char value) {
	unsigned char *p = alloca(size);
	
#ifdef DEBUG
	printf("ds %u, %u\n", size, value);
#endif
	memset(p, value, size);
	buffer_add_mem(binary, p, size);
}

static void write_bytes(const char *mem, size_t length) {
#ifdef DEBUG
	if(length == 0)
		puts("db");
	else {
		size_t i;
		
		printf("db %u", mem[0]);
		for(i = 1; i < length; ++i)
			printf(", %u", mem[i]);
		putchar('\n');
	}
#endif
	buffer_add_mem(binary, mem, length);
}


static void jp(int has_flag, unsigned char flag, uint16_t address) {
	unsigned char mem[3];
	
	if(has_flag) {
#ifdef DEBUG
		printf("jp %s, %u\n", FLAG(flag), address);
#endif
		mem[0] = 0xc2 | (flag << 3);
	}
	else {
#ifdef DEBUG
		printf("jp %u\n", address);
#endif
		mem[0] = 0xc3;
	}
	
	mem[1] = address & 0xff;
	mem[2] = address >> 8;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void jr(int has_flag, unsigned char flag, unsigned char offset) {
	unsigned char mem[2];
	
	if(has_flag) {
#ifdef DEBUG
		printf("jr %s, %d\n", FLAG(flag), offset);
#endif
		mem[0] = 0x20 | (flag << 3);
	}
	else {
#ifdef DEBUG
		printf("jr %d\n", offset);
#endif
		mem[0] = 0x18;
	}
	
	mem[1] = offset;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void call(int has_flag, unsigned char flag, uint16_t address) {
	unsigned char mem[3];
	
	if(has_flag) {
#ifdef DEBUG
		printf("call %s, %u\n", FLAG(flag), address);
#endif
		mem[0] = 0xc4 | (flag << 3);
	}
	else {
#ifdef DEBUG
		printf("call %u\n", address);
#endif
		mem[0] = 0xcd;
	}
	
	mem[1] = address & 0xff;
	mem[2] = address >> 8;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void ret(unsigned char flag) {
#ifdef DEBUG
	printf("ret %s\n", FLAG(flag));
#endif
	
	unsigned char opcode = 0xc0;
	opcode |= flag << 3;
	
	buffer_add_char(binary, opcode);
}


static void ld_simple(unsigned char dest, unsigned char source) {
#ifdef DEBUG
	printf("ld %s, %s\n", SREG(dest), SREG(source));
#endif
	
	if(source == 6 && dest == 6) {
		yyerror("ld [hl], [hl] is not possible!");
		exit(1);
	}
	
	unsigned char opcode;
	opcode = 0x40;
	opcode |= dest << 3;
	opcode |= source;
	
	buffer_add_char(binary, opcode);
}

static void ld_const(unsigned char dest, unsigned char c) {
#ifdef DEBUG
	printf("ld %s, %u\n", SREG(dest), c);
#endif
	
	unsigned char mem[2];
	mem[0] = 0x06 | (dest << 3);
	mem[1] = c;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void ld_bcde(unsigned char dreg, unsigned char direction) {
#ifdef DEBUG
	printf("ld %s[%s]%s\n",
		direction == REGISTER_TO_MEMORY ? "" : "a, ",
		ALUDREG(dreg),
		direction == REGISTER_TO_MEMORY ? ", a" : "");
#endif
	
	unsigned char opcode = 0x02;
	opcode |= dreg << 4;
	opcode |= direction << 3;
	
	buffer_add_char(binary, opcode);
}

static void ld_a_mem(unsigned char direction, uint16_t address) {
#ifdef DEBUG
	printf("ld %s[%u]%s\n",
		direction == REGISTER_TO_MEMORY ? "" : "a, ",
		address,
		direction == REGISTER_TO_MEMORY ? ", a" : "");
#endif
	
	unsigned char mem[3];
	mem[0] = 0xea | (direction << 4);
	mem[1] = address & 0xff;
	mem[2] = address >> 8;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void ldi_ldd(unsigned char operation, unsigned char direction) {
#ifdef DEBUG
	printf("%s %s\n",
		operation == INCREMENT ? "ldi" : "ldd",
		direction == REGISTER_TO_MEMORY ? "[hl], a" : "a, [hl]");
#endif
	
	unsigned char opcode = 0x22;
	opcode |= operation << 4;
	opcode |= direction << 3;
	
	buffer_add_char(binary, opcode);
}

static void ldh_addr(unsigned char direction, unsigned char offset) {
#ifdef DEBUG
	printf("ldh %s%u%s\n",
		direction == REGISTER_TO_MEMORY ? "" : "a, ",
		offset,
		direction == REGISTER_TO_MEMORY ? ", a" : "");
#endif
	
	unsigned char mem[2];
	mem[0] = 0xe0 | (direction << 4);
	mem[1] = offset;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void ldh_c(unsigned char direction) {
#ifdef DEBUG
	printf("ldh %s\n", direction == REGISTER_TO_MEMORY ? "[c], a" : "a, [c]");
#endif
	
	unsigned char opcode = 0xe2;
	opcode |= direction << 4;
	
	buffer_add_char(binary, opcode);
}

static void ld_const16(unsigned char dest, uint16_t c) {
#ifdef DEBUG
	printf("ld %s, %u\n", ALUDREG(dest), c);
#endif
	
	unsigned char mem[3];
	mem[0] = 0x01 | (dest << 4);
	mem[1] = c & 0xff;
	mem[2] = c >> 8;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void ldhl(unsigned char offset) {
#ifdef DEBUG
	printf("ldhl sp, %u\n", offset);
#endif
	
	unsigned char mem[2];
	mem[0] = 0xf8;
	mem[1] = offset;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void ld_sp_mem(uint16_t address) {
#ifdef DEBUG
	printf("ld [%u], sp\n", address);
#endif
	
	unsigned char mem[3];
	mem[0] = 0x08;
	mem[1] = address & 0xff;
	mem[2] = address >> 8;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}


static void aluop_simple(unsigned char operation, unsigned char reg) {
#ifdef DEBUG
	printf("%s %s\n", ALUOP(operation), SREG(reg));
#endif
	
	unsigned char opcode = 0x80;
	opcode |= operation << 3;
	opcode |= reg;
	
	buffer_add_char(binary, opcode);
}

static void aluop_const(unsigned char operation, unsigned char c) {
#ifdef DEBUG
	printf("%s %u\n", ALUOP(operation), c);
#endif
	
	unsigned char mem[2];
	mem[0] = 0xc6 | (operation << 3);
	mem[1] = c;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void add_hl(unsigned char dreg) {
#ifdef DEBUG
	printf("add hl, %s\n", ALUDREG(dreg));
#endif
	
	unsigned char opcode = 0x09;
	opcode |= dreg << 4;
	
	buffer_add_char(binary, opcode);
}

static void add_sp(unsigned char n) {
#ifdef DEBUG
	printf("add sp, %u\n", n);
#endif
	
	unsigned char mem[2];
	mem[0] = 0xe8;
	mem[1] = n;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}


static void push_pop(unsigned char operation, unsigned char reg) {
#ifdef DEBUG
	printf("%s %s\n", operation == INCREMENT ? "pop" : "push", PPDREG(reg));
#endif
	
	unsigned char opcode = 0xc1;
	opcode |= reg << 4;
	opcode |= operation << 2;
	
	buffer_add_char(binary, opcode);
}

static void inc_dec_dreg(unsigned char operation, unsigned char reg) {
#ifdef DEBUG
	printf("%s %s\n", operation == INCREMENT ? "inc" : "dec", PPDREG(reg));
#endif
	
	unsigned char opcode = 0x03;
	opcode |= reg << 4;
	opcode |= operation << 3;
	
	buffer_add_char(binary, opcode);
}

static void inc_dec_sreg(unsigned char operation, unsigned char reg) {
#ifdef DEBUG
	printf("%s %s\n", operation == INCREMENT ? "inc" : "dec", SREG(reg));
#endif
	
	unsigned char opcode = 0x04;
	opcode |= reg << 3;
	opcode |= operation;
	
	buffer_add_char(binary, opcode);
}

static void rst(unsigned int addr) {
	unsigned int tmp = addr >> 3;
	
	if(tmp << 3 != addr)
		yyerror("only 0x0, 0x8, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38 are allowed for rst");
	
#ifdef DEBUG
	printf("rst %x\n", addr);
#endif
	
	unsigned char opcode = 0xc7;
	opcode |= tmp << 3;
	
	buffer_add_char(binary, opcode);
}

static void cb_function(unsigned char function, unsigned char reg) {
#ifdef DEBUG
	printf("%s %s\n", CB_FUNC(function), SREG(reg));
#endif
	
	unsigned char mem[2];
	mem[0] = 0xcb;
	mem[1] = (function << 3) | reg;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}

static void cb_int_function(unsigned char function, unsigned int n, unsigned char reg) {
#ifdef DEBUG
	printf("%s %u, %s\n", CB_INT_FUNC(function), n, SREG(reg));
#endif
	
	unsigned char mem[2];
	mem[0] = 0xcb;
	mem[1] = (function << 6) | (n << 3) | reg;
	
	buffer_add_mem(binary, mem, sizeof(mem));
}
