#include "stage.h"
__sfr __at(0xa0) psg_address;
__sfr __at(0xa1) psg_write;
__sfr __at(0xa2) psg_read;
volatile unsigned char music_enabled = 1, music_restart;
volatile unsigned int music_ticks;
/* Original eight-second loop: 120 BPM, eighth-note steps, PSG only.
 * Periods use the standard MSX 1.7897725 MHz PSG clock. */
static const unsigned int melody[32] = {214, 170, 143, 170, 160, 127, 107, 127, 180, 143, 120,
                                        143, 160, 127, 107, 143, 214, 170, 143, 107, 160, 127,
                                        107, 85,  180, 143, 120, 95,  160, 143, 127, 170};
static const unsigned int bass[4] = {855, 640, 719, 640};
static unsigned char phase, step, io_direction;
static unsigned char volume(unsigned char level) {
    unsigned char fade = white_level >> 1;
    return level > fade ? level - fade : 0;
}
static void write_psg(unsigned char reg, unsigned char value) {
    psg_address = reg;
    psg_write = value;
}
void music_init(void) {
    psg_address = 7;
    io_direction = psg_read & 0xc0; /* Preserve joystick / I/O directions. */
    write_psg(7, io_direction | 0x38);
    write_psg(8, 0);
    write_psg(9, 0);
    write_psg(10, 0);
    phase = 0;
    step = 0;
    music_ticks = 0;
    music_restart = 0;
}
void music_tick(void) {
    unsigned int period;
    unsigned char accent;
    if (music_restart) {
        phase = 0;
        step = 0;
        music_ticks = 0;
        music_restart = 0;
    }
    if (!music_enabled || paused || white_level == 31) {
        write_psg(8, 0);
        write_psg(9, 0);
        write_psg(10, 0);
        return;
    }
    if (!phase) {
        period = melody[step];
        write_psg(0, (unsigned char)period);
        write_psg(1, period >> 8);
        period = bass[step >> 3];
        write_psg(2, (unsigned char)period);
        write_psg(3, period >> 8);
        /* Short noise hits alternating with a pitched percussive pulse. */
        accent = !(step & 3);
        write_psg(4, 96);
        write_psg(5, 2);
        write_psg(6, accent ? 18 : 3);
        write_psg(7, io_direction | (accent ? 0x1c : 0x38));
    }
    write_psg(8, volume(phase < 3 ? 10 : (phase < 8 ? 8 : 5)));
    write_psg(9, volume(phase < 9 ? 9 : 5));
    write_psg(10, volume(phase < 2 ? 10 : (phase < 4 ? 6 : 0)));
    music_ticks++;
    if (++phase == 15) {
        phase = 0;
        step = (step + 1) & 31;
    }
}