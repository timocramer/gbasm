jp forward
ds 10, 0x69
forward:
ld a, a
call nz, forward2
dm "Hallo, ich bin der Timo"
forward2:
ld a, a
