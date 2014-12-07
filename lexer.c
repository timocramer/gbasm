#include <string.h>
#include <strings.h>
#include <ctype.h>
#include <limits.h>

#include "gbparse.h"
#include "buffer.h"
#include "errors.h"

#ifdef DEBUG
#include <stdio.h>
#endif

extern char *src;

struct element {
	char op[7];
	int tok;
};

static const struct element operators[] = {
	{.op = "&&", .tok = LOGAND},
	{.op = "||", .tok = LOGOR},
	{.op = "==", .tok = EQ},
	{.op = "!=", .tok = NEQ},
	{.op = "<<", .tok = LSHIFT},
	{.op = ">>", .tok = RSHIFT},
	{.op = "<=", .tok = LE},
	{.op = ">=", .tok = GE}
};

static int scan_operator(void) {
	size_t i;
	size_t len;
	
	for(i = 0; i < sizeof(operators) / sizeof(operators[0]); ++i) {
		len = strlen(operators[i].op);
		if(strncmp(src, operators[i].op, len) == 0) {
			src += len;
			yylloc.last_column += len;
#ifdef DEBUG
			printf("yylex returns %s\n", operators[i].op);
#endif
			return operators[i].tok;
		}
	}
	return 0;
}

static unsigned int chr2int(unsigned char x) {
	if(x >= '0' && x <= '9')
		return x - '0';
	x &= ~0x20; // make lowercase letters uppercase
	if(x >= 'A' && x <= 'Z')
		return x - 'A' + 10;
	return UINT_MAX;
}

static void scan_uint(unsigned int base) {
	unsigned int i = 0;
	unsigned int c;
	
	while(1) {
		c = chr2int(*src);
		if(c >= base) /* this also includes the UINT_MAX case */
			break;
		i *= base;
		i += c;
		++src;
		++yylloc.last_column;
	}
	/* maybe we should check for whitespace or something */
	
	yylval.integer = i;
}

static char slash_char(const char c) {
	switch(c) {
	case 'a': return '\a';
	case 'b': return '\b';
	case 'e': return '\e';
	case 'f': return '\f';
	case 'n': return '\n';
	case 'r': return '\r';
	case 't': return '\t';
	case 'v': return '\v';
	default: return c;
	}
}

static void scan_char(void) {
	char new_char;
	
	if(*src == 0 || *(src + 1) == 0) {
		does_not_end:
		location_error(yylloc, "character constant does not end");
		return;
	}
	
	if(*src == '\\') {
		++src;
		++yylloc.last_column;
		if(*(src + 1) == 0)
			goto does_not_end;
		if(*(src + 1) != '\'')
			goto too_long;
		
		new_char = slash_char(*src);
	}
	else if(*(src + 1) == '\'')
		new_char = *src;
	else {
		too_long:
		location_error(yylloc, "character constant is too long");
		return;
	}
	
	yylval.integer = new_char;
	
	if(new_char == '\n') {
		++yylloc.last_line;
		yylloc.last_column = 1;
	}
	else
		++yylloc.last_column;
	++yylloc.last_column; /* for the '-char */
	src += 2;
}

static int scan_int(void) {
	if(*src == '\'') {
		++src;
		++yylloc.last_column;
		scan_char();
	}
	else if(*src == '0') {
		++src;
		++yylloc.last_column;
		if(*src == 'x') {
			++src;
			++yylloc.last_column;
			scan_uint(16);
		}
		else if(*src == 'b') {
			++src;
			++yylloc.last_column;
			scan_uint(2);
		}
		else {
			--src; /* we go one char back to recognize a single '0' */
			--yylloc.last_column;
			scan_uint(8);
		}
	}
	else if(isdigit(*src))
		scan_uint(10);
	else
		return 0;
	
#ifdef DEBUG
	printf("yylex returns %d\n", yylval.integer);
#endif
	return INTEGER;
}

static int scan_string(void) {
	char new_char;
	struct buffer buf;
	
	if(*src != '"')
		return 0;
	
	buffer_init(&buf);
	++yylloc.last_column;
	++src;
	
	while(*src != '"') {
		if(*src == 0) {
			string_does_not_end:
			location_error(yylloc, "String does not end");
		}
		
		if(*src == '\\') {
			++yylloc.last_column;
			++src;
			if(*src == 0)
				goto string_does_not_end;
			if(*src == '\n') { /* backslash newline means ignore newline */
				++yylloc.last_line;
				yylloc.last_column = 1;
				++src;
				continue;
			}
			
			new_char = slash_char(*src);
		}
		else
			new_char = *src;
		
		buffer_add_char(&buf, new_char);
		if(*src == '\n') {
			++yylloc.last_line;
			yylloc.last_column = 1;
		}
		else
			++yylloc.last_column;
		++src;
	}
	
	buffer_add_char(&buf, 0);
	yylval.string = buf.data;
	
#ifdef DEBUG
	printf("yylex returns \"%s\"\n", yylval.string);
#endif
	
	++yylloc.last_column;
	++src; /* now src points to the char after the " */
	return STRING;
}

#define ENTRY(token) {.op = #token, .tok = token}
static const struct element tokentable[] = {
	ENTRY(A),
	ENTRY(ADC),
	ENTRY(ADD),
	ENTRY(AF),
	ENTRY(AND),
	ENTRY(B),
	ENTRY(BC),
	ENTRY(BIT),
	ENTRY(C),
	ENTRY(CALL),
	ENTRY(CCF),
	ENTRY(CP),
	ENTRY(CPL),
	ENTRY(D),
	ENTRY(DAA),
	ENTRY(DB),
	ENTRY(DE),
	ENTRY(DEC),
	{.op = "DEFB", .tok = DB},
	ENTRY(DEFINE),
	{.op = "DEFM", .tok = DM},
	{.op = "DEFS", .tok = DS},
	{.op = "DEFW", .tok = DW},
	ENTRY(DI),
	ENTRY(DM),
	ENTRY(DS),
	ENTRY(DW),
	ENTRY(E),
	ENTRY(EI),
	ENTRY(H),
	ENTRY(HALT),
	ENTRY(HL),
	ENTRY(INC),
	ENTRY(JP),
	ENTRY(JR),
	ENTRY(L),
	ENTRY(LD),
	ENTRY(LDD),
	ENTRY(LDH),
	ENTRY(LDHL),
	ENTRY(LDI),
	ENTRY(NC),
	ENTRY(NOP),
	ENTRY(NZ),
	ENTRY(OR),
	ENTRY(POP),
	ENTRY(PUSH),
	ENTRY(RES),
	ENTRY(RET),
	ENTRY(RETI),
	ENTRY(RL),
	ENTRY(RLA),
	ENTRY(RLC),
	ENTRY(RLCA),
	ENTRY(RR),
	ENTRY(RRA),
	ENTRY(RRC),
	ENTRY(RRCA),
	ENTRY(RST),
	ENTRY(SBC),
	ENTRY(SCF),
	ENTRY(SEEK),
	ENTRY(SET),
	ENTRY(SLA),
	ENTRY(SP),
	ENTRY(SRA),
	ENTRY(SRL),
	ENTRY(STOP),
	ENTRY(SUB),
	ENTRY(SWAP),
	ENTRY(XOR),
	ENTRY(Z)
};
#undef ENTRY

#define IDENTIFIER_CHAR(x) (isalnum(x) || (x) == '_')

static int scan_special_identifier(void) {
	size_t i;
	size_t len;
	
	/* when there is no identifier, we don't need to go through this whole table */
	if(!IDENTIFIER_CHAR(*src))
		return 0;
	
	for(i = 0; i < sizeof(tokentable) / sizeof(tokentable[0]); ++i) {
		len = strlen(tokentable[i].op);
		if(strncasecmp(src, tokentable[i].op, len) == 0 && !IDENTIFIER_CHAR(src[len])) {
			src += len;
			yylloc.last_column += len;
#ifdef DEBUG
			printf("yylex returns token %s\n", tokentable[i].op);
#endif
			return tokentable[i].tok;
		}
	}
	return 0;
}

static int scan_identifier(void) {
	struct buffer buf;
	
	/* for the first char, no numbers are allowed */
	if(isalpha(*src) || *src == '_') {
		buffer_init(&buf);
		buffer_add_char(&buf, *src);
	}
	else
		return 0;
	++yylloc.last_column;
	++src;
	
	while(IDENTIFIER_CHAR(*src)) {
		buffer_add_char(&buf, *src);
		++yylloc.last_column;
		++src;
	}
	buffer_add_char(&buf, 0);
	
	yylval.identifier = buf.data;
#ifdef DEBUG
	printf("yylex returns identifier %s\n", yylval.identifier);
#endif
	
	return IDENTIFIER;
}

int yylex(void) {
	int status;
	
#ifdef DEBUG
	printf("yylex is called\n"
		"  first_line:   %d\n"
		"  first_column: %d\n"
		"  last_line:    %d\n"
		"  last_column:  %d\n",
		yylloc.first_line,
		yylloc.first_column,
		yylloc.last_line,
		yylloc.last_column);
#endif
	
	skip_white_space:
	while(*src == ' ' || *src == '\t') {
		++yylloc.last_column;
		++src;
	}
	
	/* skip comments */
	if(*src == ';') {
		while(*src != '\n' && *src != 0) {
			++yylloc.last_column;
			++src;
		}
	}
	
	/* when a newline appears, update yylloc accordingly and start to skip
	whitespace again */
	if(*src == '\n') {
		++yylloc.last_line;
		yylloc.last_column = 1;
		++src;
		goto skip_white_space;
	}
	
	yylloc.first_line = yylloc.last_line;
	yylloc.first_column = yylloc.last_column;
	
	status = scan_operator();
	if(status != 0)
		return status;
	
	status = scan_int();
	if(status != 0)
		return status;
	
	status = scan_string();
	if(status != 0)
		return status;
	
	status = scan_special_identifier();
	if(status != 0)
		return status;
	
	status = scan_identifier();
	if(status != 0)
		return status;
	
	/* Return a single char or, when end of string, 0 */
	++yylloc.last_column;
#ifdef DEBUG
	if(*src == 0)
		printf("yylex returns EOF\n");
	else
		printf("yylex returns '%c'\n", *src);
#endif
	return *src++;
}
