#include "stage.h"
#include "motion_data.h"
#include <arch/z80.h>
#include <string.h>
__sfr __at(0x9d) geo_index;
__sfr __at(0x9f) geo_data;
unsigned int selected_bank;
static int matrix[9], distance;
static int visible_bounds[6], focus[3];
static const unsigned char *pose;
static int qmul(int a, int b) {
    if (!a || !b)
        return 0;
    if (a == 16384)
        return b;
    if (a == -16384)
        return -b;
    return (int)(((long)a * b) >> 14);
}
static void word(int v) {
    geo_data = v;
    geo_data = v >> 8;
}
static void reg(unsigned char r, unsigned char v) {
    geo_index = r;
    geo_data = v;
}
static void stream(const unsigned char *p, unsigned int size) {
    unsigned char n;
    while (size) {
        n = size > 255 ? 255 : size;
        z80_otir(p, 0x9f, n);
        p += n;
        size -= n;
    }
}
static void wait_geo(void) {
    unsigned int budget = 65535;
    while (geo_index & 1) {
        if (!--budget) {
            video_error = 3;
            break;
        }
    }
    video_wait();
}
static void run(unsigned char nv, unsigned char nf) {
    reg(0x42, nv);
    reg(0x59, nf);
    geo_index = 0x46;
    word(video_draw_y());
    video_wait();
    reg(0x48, 3);
    wait_geo();
}
static void setup_camera(void) {
    int sy = trig_sine(camera_yaw), cy = trig_sine(camera_yaw + 64), sx = trig_sine(camera_pitch),
        cx = trig_sine(camera_pitch + 64);
    int x, y, z, tx, ty, tz, need, d = 64;
    unsigned char corner, i;
    matrix[0] = cy;
    matrix[1] = 0;
    matrix[2] = sy;
    matrix[3] = qmul(sx, sy);
    matrix[4] = cx;
    matrix[5] = -qmul(sx, cy);
    matrix[6] = -qmul(cx, sy);
    matrix[7] = sx;
    matrix[8] = qmul(cx, cy);
    /* Fit all eight corners, including optional reflection, with 12 px margin.
     * Perspective uses d+z; solve each x/y/near constraint for d. */
    for (corner = 0; corner < 8; corner++) {
        x = visible_bounds[(corner & 1) ? 3 : 0] - focus[0];
        y = visible_bounds[(corner & 2) ? 4 : 1] - focus[1];
        z = visible_bounds[(corner & 4) ? 5 : 2] - focus[2];
        tx = qmul(matrix[0], x) + qmul(matrix[2], z);
        ty = qmul(matrix[3], x) + qmul(matrix[4], y) + qmul(matrix[5], z);
        tz = qmul(matrix[6], x) + qmul(matrix[7], y) + qmul(matrix[8], z);
        if (tx < 0)
            tx = -tx;
        if (ty < 0)
            ty = -ty;
        need = (int)((unsigned long)tx * 40 / 29) - tz;
        if (need > d)
            d = need;
        need = (int)((unsigned long)ty * 20 / 11) - tz;
        if (need > d)
            d = need;
        need = 64 - tz;
        if (need > d)
            d = need;
    }
    distance = (int)((long)(d + 12) * camera_zoom / 100);
    geo_index = 0;
    for (i = 0; i < 9; i++)
        word(matrix[i]);
    for (i = 0; i < 3; i++)
        word(-qmul(matrix[i * 3], focus[0]) - qmul(matrix[i * 3 + 1], focus[1]) -
             qmul(matrix[i * 3 + 2], focus[2]) + (i == 2 ? distance : 0));
    geo_index = 0x18;
    word(SCREEN_FOCAL);
    word(SCREEN_WIDTH / 2);
    word(SCREEN_HEIGHT / 2);
    word(48);
    word(SCREEN_WIDTH);
    word(SCREEN_HEIGHT);
}
static void load_pose(unsigned int frame) {
    unsigned int bank = MOTION_BANK + frame / 4;
    /* ASCII16-X: upper bank bits are address bits 8..11; low bits are data.
     * All executing code, BSS, stack and BIOS IRQ remain outside page 1. */
    *(volatile unsigned char *)(0x6000 | (bank & 0x0f00)) = (unsigned char)bank;
    selected_bank = bank;
    /* Keep this bank pinned until drawing completes: stream straight from
     * ROM. The interrupt handler never changes cartridge banks. */
    pose = (const unsigned char *)(0x4000 + (frame & 3) * FRAME_BYTES);
}
static void include_bounds(unsigned char first) {
    const int *v = (const int *)(pose + (actor_mode ? (actor_mode - 1) * 360 : 0));
    unsigned char i, j, count = actor_mode ? 60 : 180;
    int n;
    if (first)
        for (j = 0; j < 3; j++) {
            visible_bounds[j] = 32767;
            visible_bounds[j + 3] = -32767;
        }
    for (i = 0; i < count; i++)
        for (j = 0; j < 3; j++) {
            n = *v++;
            if (n < visible_bounds[j])
                visible_bounds[j] = n;
            if (n > visible_bounds[j + 3])
                visible_bounds[j + 3] = n;
        }
}
static void light(unsigned char mode) {
    geo_index = 0x5a;
    if (mode) {
        word(0);
        word(0);
        word(0);
    } else {
        word(-6000);
        word(9000);
        word(-12000);
    }
}
static void draw_pose(unsigned char mirror) {
    unsigned char actor = actor_mode ? actor_mode - 1 : 0, nv = actor_mode ? 60 : 180,
                  nf = actor_mode ? 72 : 216;
    const unsigned char *v = pose + actor * 360, *f = pose + VERTEX_BYTES + actor * 792;
    unsigned char i, a, b, c, d;
    int x, y, z, nx, ny, nz;
    reg(0x40, 0);
    geo_index = 0x50;
    if (!mirror)
        stream(v, (unsigned int)nv * 6);
    else
        for (i = 0; i < nv; i++) {
            x = *(const int *)v;
            y = *(const int *)(v + 2);
            z = *(const int *)(v + 4);
            v += 6;
            word(x);
            word(2 * FLOOR_Y - y);
            word(z);
        }
    reg(0x58, 0);
    geo_index = 0x52;
    if (!mirror && !actor_mode)
        stream(f, (unsigned int)nf * 11);
    else
        for (i = 0; i < nf; i++) {
            a = f[0] - actor * 60;
            b = f[1] - actor * 60;
            c = f[2] - actor * 60;
            d = f[3] - actor * 60;
            nx = *(const int *)(f + 4);
            ny = *(const int *)(f + 6);
            nz = *(const int *)(f + 8);
            geo_data = a;
            geo_data = mirror ? c : b;
            geo_data = mirror ? b : c;
            geo_data = mirror ? b : d;
            word(nx);
            word(mirror ? -ny : ny);
            word(nz);
            geo_data = mirror ? 12 : 1;
            f += 11;
        }
    light(mirror);
    run(nv, nf);
}
static void draw_trace(unsigned char color) {
    const unsigned char *v = pose + (actor_mode ? (actor_mode - 1) * 360 : 0);
    unsigned char i, edges = actor_mode ? 12 : 36;
    /* Each five-vertex part begins with its two bone endpoints. Past poses
     * use these lines, avoiding another filled-mesh pass for every ghost. */
    reg(0x40, 0);
    geo_index = 0x50;
    for (i = 0; i < edges; i++) {
        stream(v, 12);
        v += 30;
    }
    reg(0x41, 0);
    geo_index = 0x51;
    for (i = 0; i < edges; i++) {
        geo_data = i * 2;
        geo_data = i * 2 + 1;
    }
    reg(0x42, edges * 2);
    reg(0x43, edges);
    reg(0x44, color);
    geo_index = 0x46;
    word(video_draw_y());
    video_wait();
    reg(0x48, 1);
    wait_geo();
}
static void floor_draw(void) {
    int v[75];
    unsigned char face[176];
    unsigned char x, z, i = 0, k = 0, a;
    video_floor(SCREEN_HEIGHT / 2 +
                (int)((long)trig_sine(camera_pitch) * SCREEN_FOCAL / trig_sine(camera_pitch + 64)));
    for (z = 0; z < 5; z++)
        for (x = 0; x < 5; x++) {
            v[i++] = focus[0] + ((int)x - 2) * 175;
            v[i++] = FLOOR_Y;
            v[i++] = focus[2] + ((int)z - 2) * 175;
        }
    for (z = 0; z < 4; z++)
        for (x = 0; x < 4; x++) {
            a = z * 5 + x;
            face[k++] = a;
            face[k++] = a + 5;
            face[k++] = a + 6;
            face[k++] = a + 1;
            for (i = 0; i < 6; i++)
                face[k++] = 0;
            face[k++] = 10 + ((x + z) & 1);
        }
    reg(0x40, 0);
    geo_index = 0x50;
    stream((unsigned char *)v, 150);
    reg(0x58, 0);
    geo_index = 0x52;
    stream(face, 176);
    light(1);
    run(25, 16);
}
void scene_init(void) {
    reg(0x45, 0);
}
void scene_draw(unsigned int frame) {
    unsigned char i;
    load_pose(frame);
    include_bounds(1);
    if (trails) {
        load_pose((frame + MOTION_FRAMES - 4) % MOTION_FRAMES);
        include_bounds(0);
        load_pose((frame + MOTION_FRAMES - 2) % MOTION_FRAMES);
        include_bounds(0);
    }
    if (reflection && 2 * FLOOR_Y - visible_bounds[4] < visible_bounds[1])
        visible_bounds[1] = 2 * FLOOR_Y - visible_bounds[4];
    for (i = 0; i < 3; i++) {
        visible_bounds[i] -= 4;
        visible_bounds[i + 3] += 4;
        focus[i] = (visible_bounds[i] + visible_bounds[i + 3]) / 2;
    }
    video_clear();
    setup_camera();
    floor_draw();
    if (reflection) {
        load_pose(frame);
        draw_pose(1);
    }
    if (trails) {
        load_pose((frame + MOTION_FRAMES - 4) % MOTION_FRAMES);
        draw_trace(8);
        load_pose((frame + MOTION_FRAMES - 2) % MOTION_FRAMES);
        draw_trace(9);
    }
    load_pose(frame);
    draw_pose(0);
}
