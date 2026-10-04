#include "stage.h"
#include <arch/z80.h>
static unsigned char interrupt_ready;

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
 push bc
 ld a,(_video_control_port)
 ld c,a
 xor a
 out (c),a
 ld a,0x8f
 out (c),a
 in a,(c)
 and 0x80
 jr z,motion_irq_end
 ld hl,(_vblank_ticks)
 inc hl
 ld (_vblank_ticks),hl
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
 call _demo_tick
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
motion_irq_end:
 pop bc
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
    interrupt_ready = 1;
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
        z80_outp(video_control_port, v);
    z80_outp(video_control_port, r | 128);
    // clang-format off
    if (interrupt_ready) {
#asm
 ei
#endasm
    }
    // clang-format on
}
static unsigned char status(unsigned char r) {
    unsigned char result;
    // clang-format off
#asm
 di
#endasm
        // clang-format on
        z80_outp(video_control_port, r);
    z80_outp(video_control_port, 143);
    result = z80_inp(video_control_port);
    z80_outp(video_control_port, 0);
    z80_outp(video_control_port, 143);
    // clang-format off
    if (interrupt_ready) {
#asm
 ei
#endasm
    }
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
    unsigned char blocks = platform_r800 ? 4 : 1;
    if (video_error) return;
    while (status(2) & 1) {
        if (!--budget) {
            if (--blocks) { budget = 65535; continue; }
            video_error = 1;
            break;
        }
    }
}
void video_init(void) {
    unsigned char i, j;
    interrupt_ready = 0;
    video_detect();
    if (video_error) return;
    back_page = 0;
    displayed_frames = 0;
    video_reg(1, 0x00); /* Disable BIOS VBlank before reconfiguring the VDP. */
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
            z80_outp(video_palette_port, palette[i][j]);
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
        z80_otir(packet, video_command_port, 11);
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
            z80_outp(video_palette_port, palette[i][j] + (unsigned int)(31 - palette[i][j]) * level / 31);
}
void video_idle(void) {
    unsigned int t, budget = 65535;
    unsigned char blocks = platform_r800 ? 4 : 1;
    if (video_error)
        return;
    t = clock_ticks();
    while (clock_ticks() == t) {
        if (!--budget) {
            if (--blocks) { budget = 65535; continue; }
            video_error = 4; /* Missing VBlank: report instead of hanging. */
            return;
        }
    }
}
void video_flip(void) {
    video_wait();
    video_idle();
    if (video_error) return;
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
            z80_otir(copy, video_command_port, 15);
        }
    }
#endif
    ++displayed_frames;
}
