#include "stage.h"
#include "../lib/libv9968/v9968.h"
#include "../lib/libv9968/geo3d.h"
unsigned char video_control_port, video_palette_port, video_command_port;
unsigned char geo_index_port, geo_data_port, video_external, video_type;
static unsigned char bios_control_port, bios_port_valid;
void video_detect(void) {
#asm
 di
#endasm
    video_error=video_external=0;video_type=255;
    bios_control_port=*(const unsigned char*)6+1;
    bios_port_valid=*(const unsigned char*)6==*(const unsigned char*)7&&*(const unsigned char*)0x2d>=1;
    if(!bios_port_valid){video_error=2;return;}
    v9968_select(bios_control_port-1);
    v9968_reg(1,*(unsigned char*)0xf3e0&0xdf);
    v9968_reg(0,*(unsigned char*)0xf3df&0xef);
    video_error=v9968_detect(bios_control_port-1);
    video_control_port=v9968_control_port;video_palette_port=v9968_palette_port;
    video_command_port=v9968_command_port;video_external=v9968_external;video_type=v9968_type;
    geo3d_attach();geo_index_port=geo3d_index_port;geo_data_port=geo3d_data_port;
    if(video_error)return;
    v9968_reg(1,0);v9968_reg(0,0);video_error=geo3d_probe();
}
void video_fail(void) {
    unsigned char border=video_error==5?10:video_error==4?9:14;
#asm
 di
#endasm
    if(bios_port_valid){v9968_out(bios_control_port,border);v9968_out(bios_control_port,135);}
    if(video_type==3)v9968_reg(7,border);
    v9968_out(0xa0,7);v9968_out(0xa1,0xbf);
    v9968_out(0xa0,8);v9968_out(0xa1,0);v9968_out(0xa0,9);v9968_out(0xa1,0);v9968_out(0xa0,10);v9968_out(0xa1,0);
    for(;;){}
}
