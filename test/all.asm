#define d16 0xffff
#define a16 0xffff

#define d8 0xff
#define r8 0xff
#define a8 0xff

NOP
LD BC, d16
LD [BC], A
INC BC
INC B
DEC B
LD B, d8
RLCA
LD [a16], SP
ADD HL, BC
LD A, [BC]
DEC BC
INC C
DEC C
LD C, d8
RRCA
STOP
LD DE, d16
LD [DE], A
INC DE
INC D
DEC D
LD D, d8
RLA
JR r8
ADD HL, DE
LD A, [DE]
DEC DE
INC E
DEC E
LD E, d8
RRA
JR NZ, r8
LD HL, d16
LDI [HL], A
INC HL
INC H
DEC H
LD H, d8
DAA
JR Z, r8
ADD HL, HL
LDI A, [HL]
DEC HL
INC L
DEC L
LD L, d8
CPL
JR NC, r8
LD SP, d16
LDD [HL], A
INC SP
INC [HL]
DEC [HL]
LD [HL], d8
SCF
JR C, r8
ADD HL, SP
LDD A, [HL]
DEC SP
INC A
DEC A
LD A, d8
CCF
LD B, B
LD B, C
LD B, D
LD B, E
LD B, H
LD B, L
LD B, [HL]
LD B, A
LD C, B
LD C, C
LD C, D
LD C, E
LD C, H
LD C, L
LD C, [HL]
LD C, A
LD D, B
LD D, C
LD D, D
LD D, E
LD D, H
LD D, L
LD D, [HL]
LD D, A
LD E, B
LD E, C
LD E, D
LD E, E
LD E, H
LD E, L
LD E, [HL]
LD E, A
LD H, B
LD H, C
LD H, D
LD H, E
LD H, H
LD H, L
LD H, [HL]
LD H, A
LD L, B
LD L, C
LD L, D
LD L, E
LD L, H
LD L, L
LD L, [HL]
LD L, A
LD [HL], B
LD [HL], C
LD [HL], D
LD [HL], E
LD [HL], H
LD [HL], L
HALT
LD [HL], A
LD A, B
LD A, C
LD A, D
LD A, E
LD A, H
LD A, L
LD A, [HL]
LD A, A
ADD A, B
ADD A, C
ADD A, D
ADD A, E
ADD A, H
ADD A, L
ADD A, [HL]
ADD A, A
ADC A, B
ADC A, C
ADC A, D
ADC A, E
ADC A, H
ADC A, L
ADC A, [HL]
ADC A, A
SUB B
SUB C
SUB D
SUB E
SUB H
SUB L
SUB [HL]
SUB A
SBC A, B
SBC A, C
SBC A, D
SBC A, E
SBC A, H
SBC A, L
SBC A, [HL]
SBC A, A
AND B
AND C
AND D
AND E
AND H
AND L
AND [HL]
AND A
XOR B
XOR C
XOR D
XOR E
XOR H
XOR L
XOR [HL]
XOR A
OR B
OR C
OR D
OR E
OR H
OR L
OR [HL]
OR A
CP B
CP C
CP D
CP E
CP H
CP L
CP [HL]
CP A
RET NZ
POP BC
JP NZ, a16
JP a16
CALL NZ, a16
PUSH BC
ADD A, d8
RST 0x00
RET Z
RET
JP Z, a16

CALL Z, a16
CALL a16
ADC A, d8
RST 0x08
RET NC
POP DE
JP NC, a16

CALL NC, a16
PUSH DE
SUB d8
RST 0x10
RET C
RETI
JP C, a16

CALL C, a16

SBC A, d8
RST 0x18
LDH [a8], A
POP HL
LDH [C], A


PUSH HL
AND d8
RST 0x20
ADD SP, r8
JP HL
LD [a16], A



XOR d8
RST 0x28
LDH A, [a8]
POP AF
LDH A, [C]
DI

PUSH AF
OR d8
RST 0x30
LDHL SP, r8
LD SP, HL
LD A, [a16]
EI


CP d8
RST 0x38
