/* Detection algorithm adapted from HRA! (Copyright 2025 t.hara).
 * Scoped MIT notice: licenses/MIT-VDP-DETECT.txt. */
#include "stage.h"
#include <arch/z80.h>
#pragma disable_warning 85 /* Naked routines consume their argument in HL. */

unsigned char video_control_port, video_palette_port, video_command_port;
unsigned char geo_index_port, geo_data_port, video_external, video_type;
static unsigned char bios_control_port;
static unsigned char bios_port_valid;

/* Fast byte/word writes keep streaming geometry inexpensive on Z80.
 * All port numbers are selected once, before the interrupt handler runs. */
void geo_write_index(unsigned char value) __z88dk_fastcall __naked {
#asm
 ld a,(_geo_index_port)
 ld c,a
 out (c),l
 ret
#endasm
}
void geo_write_byte(unsigned char value) __z88dk_fastcall __naked {
#asm
 ld a,(_geo_data_port)
 ld c,a
 out (c),l
 ret
#endasm
}
void geo_write_word(int value) __z88dk_fastcall __naked {
#asm
 ld a,(_geo_data_port)
 ld c,a
 out (c),l
 out (c),h
 ret
#endasm
}
unsigned char geo_status(void) { return z80_inp(geo_index_port); }

static void raw_reg(unsigned char port, unsigned char reg, unsigned char value) {
    z80_outp(port, value);
    z80_outp(port, reg | 128);
}
/* HRA!'s check_v99x8 algorithm: S1, clear R21.FID, S1 again,
 * then restore the S0 selector. No drawing commands are started here.
 * Port numbers come from BIOS page 0, which the ROM loader keeps mapped. */
static unsigned char probe(unsigned char port, unsigned char external) {
    unsigned char id, first;
    if (external) {
        first = z80_inp(port);
        if ((first & 128) && (z80_inp(port) & 128)) return 255;
    }
    /* Match working FPGA demos: port4 bit 7 = 0 unlocks R20/R21.
     * Do this before the R21-based ID probe (99h -> 9Ch, 89h -> 8Ch). */
    z80_outp(port + 3, 0);
    raw_reg(port, 15, 1);
    id = (z80_inp(port) >> 1) & 31;
    if (id) {
        raw_reg(port, 21, *(unsigned char *)0xfff4 & 254);
        id = (z80_inp(port) >> 1) & 31;
    } else {
        id = 1; /* V9938 has S1 ID zero. */
    }
    raw_reg(port, 15, 0);
    return id;
}
static unsigned char probe_geo(void) {
    unsigned char saved, ok;
    /* COLOR is a read/write register in the FPGA and emulator. Two
     * distinct values reject an undriven bus; restore it afterwards. */
    geo_write_index(0x44);
    saved = z80_inp(geo_data_port);
    geo_write_index(0x44); geo_write_byte(0x55);
    geo_write_index(0x44); ok = z80_inp(geo_data_port) == 0x55;
    geo_write_index(0x44); geo_write_byte(0xaa);
    geo_write_index(0x44); ok &= z80_inp(geo_data_port) == 0xaa;
    geo_write_index(0x44); geo_write_byte(saved);
    return ok;
}
void video_detect(void) {
    unsigned char internal = 255, external = 255;
#asm
 di
#endasm
    video_error = video_external = 0;
    video_type = 255;
    bios_control_port = *(const unsigned char *)6 + 1;
    bios_port_valid = *(const unsigned char *)6 == *(const unsigned char *)7 &&
                      *(const unsigned char *)0x2d >= 1;
    video_control_port = bios_control_port;
    /* The two BIOS port constants must agree. MSX2 or newer only;
     * probing TMS9918 would overwrite its border register. */
    if (bios_port_valid) {
        raw_reg(bios_control_port, 1, *(unsigned char *)0xf3e0 & 0xdf);
        raw_reg(bios_control_port, 0, *(unsigned char *)0xf3df & 0xef);
        internal = probe(bios_control_port, 0);
    }
    /* An 88h BIOS port indicates the version-up adapter already maps
     * this VDP as the main one. Do not probe it twice. */
    if ((bios_control_port & 0xf0) != 0x80) external = probe(0x89, 1);
    if (external == 3) { video_control_port = 0x89; video_external = 1; video_type = 3; }
    else if (internal == 3) { video_type = 3; video_external = (bios_control_port == 0x89); }
    video_palette_port = video_control_port + 1;
    video_command_port = video_control_port + 2;
    geo_index_port = video_control_port + 4;
    geo_data_port = video_control_port + 6;
    if (video_type != 3) { video_error = 2; return; }
    raw_reg(video_control_port, 1, 0);
    raw_reg(video_control_port, 0, 0);
    if (!probe_geo()) video_error = 5;
}
void video_fail(void) {
    unsigned char border = video_error == 5 ? 10 : video_error == 4 ? 9 : 14;
#asm
 di
#endasm
    /* Diagnostic on the BIOS display, plus the chosen V9968 if present.
     * Keep interrupts/music stopped and never return to BASIC. */
    if (bios_port_valid) raw_reg(bios_control_port, 7, border);
    if (video_type == 3) raw_reg(video_control_port, 7, border);
    z80_outp(0xa0, 7); z80_outp(0xa1, 0xbf);
    z80_outp(0xa0, 8); z80_outp(0xa1, 0);
    z80_outp(0xa0, 9); z80_outp(0xa1, 0);
    z80_outp(0xa0, 10); z80_outp(0xa1, 0);
    for (;;) { }
}
