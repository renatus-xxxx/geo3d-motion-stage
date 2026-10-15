#include "stage.h"
#include "motion_data.h"

/* 60 Hz presentation clock. IRQ owns time, main owns rendering and camera.
 * wait: 0 playback, 1 white hold, 2 preparing a new first frame. */
volatile unsigned int playback_ticks, demo_hold_ticks;
volatile unsigned char demo_wait = 2, music_fade = 31;
unsigned char demo_active = 1;
unsigned int demo_loops;

void demo_tick(void) {
    if (demo_wait) {
        if (demo_wait == 1 && demo_hold_ticks < 60)
            ++demo_hold_ticks;
        music_fade = 31;
        return;
    }
    if (!paused && playback_ticks < MOTION_FRAMES * 3)
        ++playback_ticks;
    music_fade = playback_ticks > MOTION_FRAMES * 3 - 30
                     ? playback_ticks - (MOTION_FRAMES * 3 - 30) + 1 : 0;
}

unsigned int demo_time(void) {
    unsigned int t;
#ifndef MOTION_NATIVE
#asm
    di
#endasm
#endif
    t = playback_ticks;
#ifndef MOTION_NATIVE
#asm
    ei
#endasm
#endif
    return t;
}

void demo_reset(void) {
#ifndef MOTION_NATIVE
#asm
    di
#endasm
#endif
    demo_wait = 2;
    playback_ticks = demo_hold_ticks = 0;
    music_fade = 31;
    music_restart = 1;
    paused = 0;
#ifndef MOTION_NATIVE
#asm
    ei
#endasm
#endif
    trails = reflection = actor_mode = 0;
    camera_reset();
    scene_reset();
}

void demo_start(void) {
#ifndef MOTION_NATIVE
#asm
    di
#endasm
#endif
    playback_ticks = 0;
    music_fade = 0;
    music_restart = 1;
    demo_wait = 0;
#ifndef MOTION_NATIVE
#asm
    ei
#endasm
#endif
}

void demo_hold(void) {
#ifndef MOTION_NATIVE
#asm
    di
#endasm
#endif
    demo_hold_ticks = 0;
    demo_wait = 1;
#ifndef MOTION_NATIVE
#asm
    ei
#endasm
#endif
}

/* Absolute states catch up in one step even after several missed events.
 * Camera angles are 1/256 turn. Zoom >=100 preserves automatic fitting. */
void demo_update(unsigned int t) {
    unsigned int u;
    trails = (t >= 360 && t < 720) || (t >= 2100 && t < 2340);
    reflection = (t >= 720 && t < 1080) || (t >= 2100 && t < 2340);
    actor_mode = t >= 1260 && t < 1800 ? 1 + (t - 1260) / 180 : 0;
    camera_yaw = 0;
    camera_pitch = -12;
    camera_zoom = 100;
    if (t >= 1800 && t < 2100) {
        u = t - 1800;
        camera_yaw = (int)u * 24 / 300;
        camera_pitch = -12 - u * 8 / 300;
        camera_zoom = 100 + u * 15 / 300;
    } else if (t >= 2100 && t < 2340) {
        camera_yaw = 24;
        camera_pitch = -20;
        camera_zoom = 115;
    } else if (t >= 2340 && t < 3060) {
        u = t - 2340;
        camera_yaw = 24 - u * 48 / 720;
        camera_pitch = -20 + u * 10 / 720;
        camera_zoom = 115;
    } else if (t >= 3060 && t < 3780) {
        u = t - 3060;
        camera_yaw = -24 + u * 24 / 720;
        camera_pitch = -10 - u * 2 / 720;
        camera_zoom = 115 - u * 15 / 720;
    }
}
