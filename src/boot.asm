; ROM INIT -> internal RAM. Page 0 remains BIOS; page 1 is banked data.
INCLUDE "build/rom_layout.inc"
ORG $4000
defm "AB"
defw start
defw 0,0,0
defs 6,0
; openMSX/Grauw ASCII16-X identification at file offset 16.
defm "ASCII16X"
start:
    di
    ld sp,$F300
    ld b,6
    in a,($A8)
primary:
    rrca
    djnz primary
    and 3
    ld e,a
    ld d,0
    ld hl,$FCC1
    add hl,de
    ld a,(hl)
    and $80
    or e
    jp p,ram_slot
    ld e,a
    inc hl
    inc hl
    inc hl
    inc hl
    ld a,(hl)
    ld b,6
secondary:
    rrca
    djnz secondary
    and 3
    rlca
    rlca
    or e
ram_slot:
    ld h,$80
    call $0024
    di
    ld hl,helper_rom
    ld de,$E200
    ld bc,helper_end-helper
    ldir
    jp $E200
helper_rom:
PHASE $E200
helper:
    ld a,1
    ld ($6000),a
    ld hl,$4000
    ld de,$8400
    ld bc,GAME_SIZE
    ldir
    jp $8400
helper_end:
DEPHASE
