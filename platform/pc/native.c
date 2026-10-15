#include "../../src/stage.h"
#include "motion_data.h"
#include "platform/emulation/emulation.h"
#include "platform/glut/window.h"
#include <stdio.h>
#include "psg.h"
#include <stdlib.h>
#include <string.h>
unsigned char platform_r800=1;
unsigned char video_control_port,video_palette_port,video_command_port;
unsigned char geo_index_port,geo_data_port,video_external,video_type;
static unsigned char *motion_data;
static size_t motion_size;
static unsigned int ticks,render_tick;
extern volatile unsigned int vblank_ticks;
extern void controls(unsigned int elapsed);
const unsigned char *motion_bank(unsigned int bank) {
    size_t offset=(size_t)(bank-2)*16384;
    if(bank<2||offset+16384>motion_size){fprintf(stderr,"Invalid motion bank %u\n",bank);exit(1);}
    return motion_data+offset;
}
void video_detect(void) {
    video_error=v9968_detect(0x98);geo3d_attach();
    video_control_port=v9968_control_port;video_palette_port=v9968_palette_port;
    video_command_port=v9968_command_port;geo_index_port=geo3d_index_port;geo_data_port=geo3d_data_port;
    video_external=v9968_external;video_type=v9968_type;
    if(!video_error)video_error=geo3d_probe();
}
void video_fail(void) {fprintf(stderr,"Device error %u\n",video_error);exit(1);}
unsigned char pc_keyboard_row(unsigned char row) {
    unsigned char k=255;
    if(row==3){if(v9968_key('c'))k&=~1;if(v9968_key('d'))k&=~2;if(v9968_key('e'))k&=~4;}
    if(row==4){if(v9968_key('r'))k&=~128;if(v9968_key('m'))k&=~4;}
    if(row==5&&v9968_key('t'))k&=~2;
    if(row==6&&(v9968_key(16)||v9968_key('z')||v9968_key('x')))k&=~1;
    if(row==7&&v9968_key(27))k&=~4;
    if(row==8){if(v9968_key(' '))k&=~1;if(v9968_key('z'))k&=~32;if(v9968_key('x'))k&=~64;if(v9968_key(228))k&=~16;if(v9968_key(229))k&=~32;if(v9968_key(231))k&=~64;if(v9968_key(230))k&=~128;}
    return k;
}
static void frame(unsigned int elapsed) {
    unsigned int t,n;
    for(n=0;n<elapsed;n++){++ticks;v9968_emulation_step();geo3d_emulation_step();vblank_ticks=(uint16_t)ticks;demo_tick();music_tick();if(!psg_tick(60)){fprintf(stderr,"%s\n",psg_audio_error());exit(1);}controls_poll();}
    if(demo_wait==1)controls(elapsed);
    if(demo_wait==1){if(demo_active&&demo_hold_ticks>=60){++demo_loops;demo_reset();}else return;}
    if(ticks-render_tick<3&&demo_wait!=2)return;
    if(demo_wait!=1)controls(ticks-render_tick);
    render_tick=ticks;t=demo_time();if(demo_active)demo_update(t);
    motion_frame=t/3;if(motion_frame>=MOTION_FRAMES)motion_frame=MOTION_FRAMES-1;
    scene_draw(motion_frame);video_white(demo_wait==2?0:music_fade);video_flip();
    if(video_error)video_fail();
    if(demo_wait==2){video_white(0);demo_start();}else if(t>=MOTION_FRAMES*3)demo_hold();
}
static void press(unsigned char key) {
    v9968_set_key(key,1);controls_poll();controls(4);
    v9968_set_key(key,0);controls_poll();
}
static int input_test(void) {
    frame(1);press('t');if(!trails||demo_active)return 1;
    press('r');if(!reflection)return 2;
    press('c');if(actor_mode!=1)return 3;
    press(' ');if(!paused)return 4;
    press(' ');if(paused)return 5;
    press('m');if(music_enabled)return 6;
    press('m');if(!music_enabled)return 7;
    v9968_set_key(230,1);controls(4);v9968_set_key(230,0);
    if(camera_yaw!=1)return 8;
    press('d');if(!demo_active||demo_wait!=2||playback_ticks)return 9;
    frame(1);press(27);if(demo_wait!=2||playback_ticks)return 10;
    puts("PASS input: trails, reflection, character, pause, BGM, camera, demo, Esc reset");return 0;
}
static void dump(const char *path) {
    FILE *f=fopen(path,"wb");if(!f){perror(path);exit(1);}
    fwrite(v9968_emulation_vram(),1,v9968_emulation_vram_size(),f);fclose(f);
    {static unsigned char rgb[V9968_IMAGE_BYTES];uint16_t w,h;char image_path[1024];
     v9968_emulation_image(rgb,&w,&h);snprintf(image_path,sizeof(image_path),"%s.ppm",path);f=fopen(image_path,"wb");if(!f)exit(1);fprintf(f,"P6\n%u %u\n255\n",w,h);fwrite(rgb,3,(size_t)w*h,f);fclose(f);}
    {char palette_path[1024];snprintf(palette_path,sizeof(palette_path),"%s.pal",path);f=fopen(palette_path,"wb");if(!f)exit(1);fwrite(v9968_emulation_palette(),1,32,f);fclose(f);}
}
int main(int argc,char **argv) {
    const char *data="motion-banks.bin",*dump_path=NULL,*wav_path=NULL;unsigned int end=0,i,at=~0u;int test_input=0;FILE *f;
    for(i=1;i<(unsigned)argc;i++) {
        if(!strcmp(argv[i],"--wav")&&i+1<(unsigned)argc)wav_path=argv[++i];
        else if(!strcmp(argv[i],"--test-input"))test_input=1;
        else if(!strcmp(argv[i],"--data")&&i+1<(unsigned)argc)data=argv[++i];
        else if(!strcmp(argv[i],"--at")&&i+1<(unsigned)argc)at=(unsigned)atoi(argv[++i]);
        else if(!strcmp(argv[i],"--ticks")&&i+1<(unsigned)argc)end=(unsigned)atoi(argv[++i]);
        else if(!strcmp(argv[i],"--dump")&&i+1<(unsigned)argc)dump_path=argv[++i];
    }
    f=fopen(data,"rb");if(!f){perror(data);return 1;}fseek(f,0,SEEK_END);motion_size=(size_t)ftell(f);rewind(f);
    motion_data=(unsigned char*)malloc(motion_size);if(!motion_data||fread(motion_data,1,motion_size,f)!=motion_size)return 1;fclose(f);
    #ifdef V9968_NATIVE_FIL
    v9968_emulation_reset(1,0);
#else
    v9968_emulation_reset(0,0);
#endif
    psg_reset();atexit(psg_audio_close);
    if(wav_path&&!psg_wav_open(wav_path))return 1;
    geo3d_emulation_reset();music_init();video_init();scene_init();demo_reset();
    if(test_input)return input_test();
    if(at!=~0u){if(at>=MOTION_FRAMES*3)return 1;frame(1);playback_ticks=at;paused=1;frame(3);if(dump_path)dump(dump_path);printf("FIXTURE time=%u pose=%u trails=%u reflection=%u actor=%u\n",at,motion_frame,trails,reflection,actor_mode);return video_error;}
    if(end){for(i=0;i<end;i++)frame(1);if(dump_path)dump(dump_path);printf("%s ticks=%u frames=%u loops=%u white=%u\n",(video_error||(end>=4400&&demo_loops<1))?"FAIL":"PASS",ticks,displayed_frames,demo_loops,white_level);return video_error||(end>=4400&&demo_loops<1);}
    if(!psg_audio_open()){fprintf(stderr,"%s\n",psg_audio_error());return 1;}
    return v9968_window(argc,argv,"geo3d-motion-stage - native",frame);
}
