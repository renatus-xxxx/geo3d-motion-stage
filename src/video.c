#include "stage.h"
#include <arch/z80.h>
__sfr __at(0x99) vdp_control;
__sfr __at(0x9a) palette_port;
__sfr __at(0xaa) ppi_select;
__sfr __at(0xa9) ppi_keys;
unsigned char video_error, back_page;
unsigned int displayed_frames;
static void fill(unsigned int y, unsigned int height, unsigned char color);
volatile unsigned int vblank_ticks;
/* Own IM2 handler: acknowledge VBlank and increment a clock using only
 * saved registers. The PSG sequencer also runs at VBlank. No BIOS services run while ROM data banks
 * are selected. */
static void interrupt_handler(void) __naked {
    // clang-format off
#asm
 push af
 push hl
 xor a
 out (0x99),a
 ld a,0x8f
 out (0x99),a
 in a,(0x99)
 and 0x80
 jr z,motion_irq_end
 ld hl,(_vblank_ticks)
 inc hl
 ld (_vblank_ticks),hl
 push bc
 push de
 push ix
 push iy
 ex af,af'
 push af
 exx
 push bc
 push de
 push hl
 exx
 call _music_tick
 call _controls_poll
 exx
 pop hl
 pop de
 pop bc
 exx
 pop af
 ex af,af'
 pop iy
 pop ix
 pop de
 pop bc
motion_irq_end:
 pop hl
 pop af
 ei
 reti
#endasm
    // clang-format on
}
static void install_interrupt(void) {
    unsigned int i, address = (unsigned int)interrupt_handler;
    // clang-format off
#asm
 di
#endasm
        // clang-format on
        for (i = 0; i < 257; i++) *
        ((unsigned char *)0xe000 + i) = 0xe1;
    *(unsigned char *)0xe1e1 = 0xc3;
    *(unsigned int *)0xe1e2 = address;
    vblank_ticks = 0;
    // clang-format off
#asm
 ld a,0xe0
 ld i,a
 im 2
 ei
#endasm
    // clang-format on
}
static unsigned char packet[11];
static const unsigned char palette[16][3] = {
    {1, 2, 4},    {3, 7, 10},   {5, 11, 15}, {8, 15, 19}, {12, 19, 22}, {17, 23, 26},
    {23, 28, 30}, {31, 31, 31}, {3, 8, 12},  {6, 13, 17}, {2, 5, 7},    {3, 7, 9},
    {3, 10, 12},  {4, 12, 15},  {31, 6, 4},  {20, 26, 31}};
void video_reg(unsigned char r, unsigned char v) {
    // clang-format off
#asm
 di
#endasm
        // clang-format on
        vdp_control = v;
    vdp_control = r | 128;
    // clang-format off
#asm
 ei
#endasm
    // clang-format on
}
static unsigned char status(unsigned char r) {
    unsigned char result;
    // clang-format off
#asm
 di
#endasm
        // clang-format on
        vdp_control = r;
    vdp_control = 143;
    result = vdp_control;
    vdp_control = 0;
    vdp_control = 143;
    // clang-format off
#asm
 ei
#endasm
        // clang-format on
        return result;
}
unsigned int clock_ticks(void) {
    unsigned int t;
    // clang-format off
#asm
 di
#endasm
        // clang-format on
        t = vblank_ticks;
    // clang-format off
#asm
 ei
#endasm
        // clang-format on
        return t;
}
unsigned char keyboard_row(unsigned char row) {
    unsigned char save = ppi_select, k;
    ppi_select = (save & 240) | row;
    k = ppi_keys;
    ppi_select = save;
    return k;
}
void video_wait(void) {
    unsigned int budget = 65535;
    while (status(2) & 1) {
        if (!--budget) {
            video_error = 1;
            break;
        }
    }
}
void video_init(void) {
    unsigned char i, j;
    video_error = back_page = 0;
    displayed_frames = 0;
    video_reg(21, 0x3a);
    if (((status(1) >> 1) & 31) != 3) {
        video_error = 2;
        return;
    }
    video_reg(0, 0x0a);
    video_reg(1, 0x00); /* Enable VBlank only after installing the custom ISR. */
    video_reg(2, 0x3f);
    video_reg(7, 0);
    video_reg(8, 0x0a);
    video_reg(9, 0x84); /* 212 lines per field, NTSC, EO for FIL. */
#ifdef V9968_NATIVE_FIL
    video_reg(20, 0x31); /* Current FPGA: R20 bit 5 FIL. */
    video_reg(21, 0x3a);
#else
    video_reg(20, 0x11);
    video_reg(21, 0x7a); /* Bundled openMSX: legacy R21 bit 6 FIL. */
#endif
    video_reg(23, 0);
    video_reg(25, 0);
    video_reg(26, 0);
    video_reg(27, 0);
    video_reg(18, 0);
    video_reg(16, 0);
    for (i = 0; i < 16; i++)
        for (j = 0; j < 3; j++)
            palette_port = palette[i][j];
    *(unsigned char *)0xf3df = 0x0a; /* RG0SAV */
    *(unsigned char *)0xf3e0 = 0x60; /* BIOS enables VBlank interrupts. */
    *(unsigned char *)0xf3e8 = 0x84; /* RG9SAV */
    back_page = 1;
    video_clear();
    video_wait();
    back_page = 0;
    fill(0, SCREEN_HEIGHT, 0); /* Clear the displayed page, including legacy FIL. */
    video_wait();
    install_interrupt();
    video_reg(1, 0x60);
    back_page = 1;
}
unsigned int video_draw_y(void) {
#ifdef V9968_NATIVE_FIL
    return back_page ? SCREEN_PAGE_Y : 0;
#else
    return SCREEN_PAGE_Y;
#endif
}
/* Two halves avoid the bundled high-speed engine's NX=512 limitation. */
static void fill(unsigned int y, unsigned int height, unsigned char color) {
    unsigned char half, i;
    for (half = 0; half < 2; half++) {
        video_wait();
        for (i = 0; i < 11; i++)
            packet[i] = 0;
        packet[1] = half;
        packet[2] = y;
        packet[3] = y >> 8;
        packet[5] = 1;
        packet[6] = height;
        packet[7] = height >> 8;
        packet[8] = color;
        packet[10] = 0xc0;
        video_reg(17, 36);
        z80_otir(packet, 0x9b, 11);
    }
}
void video_clear(void) {
    fill(video_draw_y(), SCREEN_HEIGHT, 0);
}
void video_floor(int horizon) {
    if (horizon < 0)
        horizon = 0;
    if (horizon >= SCREEN_HEIGHT)
        return;
    fill(video_draw_y() + horizon, SCREEN_HEIGHT - horizon, 0xaa);
}
volatile unsigned char white_level;
void video_white(unsigned char level) {
    unsigned char i, j;
    if (level > 31)
        level = 31;
    if (level == white_level)
        return;
    white_level = level;
    video_reg(16, 0);
    for (i = 0; i < 16; i++)
        for (j = 0; j < 3; j++)
            palette_port = palette[i][j] + (unsigned int)(31 - palette[i][j]) * level / 31;
}
void video_flip(void) {
    unsigned int t, budget = 65535;
    video_wait();
    if (video_error)
        return;
    t = clock_ticks();
    while (clock_ticks() == t) {
        if (!--budget) {
            video_error = 4; /* Missing VBlank: report instead of hanging. */
            return;
        }
    }
#ifdef V9968_NATIVE_FIL
    video_reg(2, back_page ? 0x7f : 0x3f);
    back_page ^= 1;
#else
    /* Legacy FIL renderer cannot display upper VRAM: present by copying.
     * Complete image occupies 108544 bytes; back image starts at Y=512. */
    {
        unsigned char half;
        for (half = 0; half < 2; half++) {
            unsigned char copy[15] = {0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 168, 1, 0, 0, 0xd0};
            video_wait();
            copy[1] = half;
            copy[5] = half;
            video_reg(17, 32);
            z80_otir(copy, 0x9b, 15);
        }
    }
#endif
    ++displayed_frames;
}