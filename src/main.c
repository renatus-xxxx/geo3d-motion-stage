#include "stage.h"
#include "motion_data.h"
unsigned int motion_frame;
volatile unsigned char paused;
unsigned char trails, reflection, actor_mode;
signed char camera_yaw, camera_pitch;
unsigned char camera_zoom;
volatile unsigned int stage_ready;
static unsigned char held_keys;
static volatile unsigned char pending_keys;

void camera_reset(void) {
    camera_yaw = 0;
    camera_pitch = -12;
    camera_zoom = 100;
}
void controls_poll(void) {
    unsigned char row3 = keyboard_row(3), row4 = keyboard_row(4), row5 = keyboard_row(5);
    unsigned char row7 = keyboard_row(7), row8 = keyboard_row(8);
    /* T: Trails, R: Reflection, C: Character selection. */
    unsigned char keys = ((~row5 >> 1) & 1) | ((~row4 >> 6) & 2) | ((~row3 & 1) << 2) |
                         ((~row8 & 1) << 3) | ((~row7 & 4) << 2) | ((~row4 & 4) << 3) |
                         ((~row3 & 4) << 4) | ((~row3 & 2) << 6);
    pending_keys |= keys & ~held_keys;
    held_keys = keys;
}
static void controls(unsigned int elapsed) {
    unsigned char row6 = keyboard_row(6), row8 = keyboard_row(8), pressed;
    int step = elapsed / 4, value;
    if (step < 1)
        step = 1;
    if (step > 12)
        step = 12;
    // clang-format off
#asm
 di
#endasm
        // clang-format on
        pressed = pending_keys;
    pending_keys = 0;
    // clang-format off
#asm
 ei
#endasm
        // clang-format on
    /* D is a fresh demo; visual controls enter manual mode without a jump. */
    if (pressed & 128) {
        demo_active = 1;
        demo_reset();
        return;
    }
    if ((pressed & (1 | 2 | 4 | 8 | 64)) || (row8 & 240) != 240)
        demo_active = 0;
    if (pressed & 1) trails ^= 1;
    if (pressed & 2)
        reflection ^= 1;
    if (pressed & 4)
        actor_mode = (actor_mode + 1) & 3;
    if ((pressed & 64) && demo_wait != 2) {
#asm
        di
#endasm
        playback_ticks = MOTION_FRAMES * 3 - 30; /* E also resumes a paused ending. */
        paused = 0;
        demo_wait = 0;
#asm
        ei
#endasm
    }
    if (pressed & 32)
        music_enabled ^= 1;
    if ((pressed & 8) && !(pressed & 64))
        paused ^= 1;
    if (pressed & 16) {
        demo_reset();
        return;
    }
    if (demo_active)
        return;
    value = camera_yaw;
    if (!(row8 & 16))
        value -= step;
    if (!(row8 & 128))
        value += step;
    if (value < -32)
        value = -32;
    if (value > 32)
        value = 32;
    camera_yaw = value;
    if (!(row6 & 1)) {
        value = camera_zoom;
        if (!(row8 & 32))
            value -= step * 2;
        if (!(row8 & 64))
            value += step * 2;
        if (value < 100)
            value = 100;
        if (value > 200)
            value = 200;
        camera_zoom = value;
    } else {
        value = camera_pitch;
        if (!(row8 & 32))
            value -= step;
        if (!(row8 & 64))
            value += step;
        if (value < -26)
            value = -26;
        if (value > -3)
            value = -3;
        camera_pitch = value;
    }
}
void main(void) {
    unsigned int previous, now, elapsed, t;
    platform_init();
    music_init();
    video_init();
    if (video_error) video_fail();
    scene_init();
    demo_reset();
    previous = clock_ticks();
    stage_ready = 0x4d53;
    while (!video_error) {
        now = clock_ticks();
        elapsed = now - previous;
        previous = now;
        controls(elapsed);
        if (demo_wait == 1) {
            if (demo_active && demo_hold_ticks >= 60) {
                ++demo_loops;
                demo_reset();
            } else {
                video_idle(); /* Missing IRQ must not trap the whiteout hold. */
                continue;
            }
        }
        t = demo_time();
        if (demo_active)
            demo_update(t);
        motion_frame = t / 3;
        if (motion_frame >= MOTION_FRAMES)
            motion_frame = MOTION_FRAMES - 1;
        scene_draw(motion_frame);
        t = demo_time();
        if (demo_wait != 2)
            video_white(t > MOTION_FRAMES * 3 - 30
                            ? t - (MOTION_FRAMES * 3 - 30) + 1 : 0);
        video_flip();
        if (demo_wait == 2) {
            video_white(0); /* New page is visible before restoring its palette. */
            demo_start();
        } else if (t >= MOTION_FRAMES * 3) {
            demo_hold();
        }
    }
    /* Stop safely with a diagnostic border instead of waiting forever. */
    video_fail();
}
