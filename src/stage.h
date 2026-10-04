#ifndef STAGE_H
#define STAGE_H
#define SCREEN_WIDTH 512
#define SCREEN_HEIGHT 424
#define SCREEN_FOCAL 320
#define SCREEN_PAGE_Y 512
extern unsigned char platform_r800, video_error, back_page;
extern unsigned char video_control_port, video_palette_port, video_command_port;
extern unsigned char geo_index_port, geo_data_port, video_external, video_type;
void video_detect(void);
void video_fail(void);
void geo_write_index(unsigned char value) __z88dk_fastcall;
void geo_write_byte(unsigned char value) __z88dk_fastcall;
void geo_write_word(int value) __z88dk_fastcall;
unsigned char geo_status(void);
extern unsigned int displayed_frames, motion_frame, selected_bank;
extern volatile unsigned char paused;
extern unsigned char trails, reflection, actor_mode;
extern signed char camera_yaw, camera_pitch;
extern unsigned char camera_zoom;
extern volatile unsigned char music_enabled, music_restart;
extern volatile unsigned int music_ticks;
extern volatile unsigned int playback_ticks, demo_hold_ticks;
extern volatile unsigned char demo_wait, music_fade;
extern unsigned char demo_active;
extern unsigned int demo_loops;
void demo_tick(void);
unsigned int demo_time(void);
void demo_reset(void);
void demo_start(void);
void demo_hold(void);
void demo_update(unsigned int t);
void scene_reset(void);
void music_init(void);
void music_tick(void);
void platform_init(void);
void video_init(void);
void video_reg(unsigned char r, unsigned char v);
void video_wait(void);
void video_clear(void);
unsigned int video_draw_y(void);
void video_flip(void);
void video_idle(void);
extern volatile unsigned char white_level;
void video_white(unsigned char level);
unsigned int clock_ticks(void);
unsigned char keyboard_row(unsigned char row);
void scene_init(void);
void scene_draw(unsigned int frame);
void camera_reset(void);
void controls_poll(void);
void video_floor(int horizon);
int trig_sine(unsigned char angle) __z88dk_fastcall;
#endif
