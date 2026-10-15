#include "v9968.h"
#ifdef LIBV9968_MSX
#include <arch/z80.h>
#endif
uint8_t v9968_control_port=0x99, v9968_palette_port=0x9a, v9968_command_port=0x9b;
uint8_t v9968_external, v9968_type;
/* PC transport is supplied by the selected platform; no runtime plugins. */
#ifndef LIBV9968_MSX
extern void v9968_backend_out(uint8_t port, uint8_t value);
extern uint8_t v9968_backend_in(uint8_t port);
#endif
void v9968_out(uint8_t port,uint8_t value) {
#ifdef LIBV9968_MSX
    z80_outp(port,value);
#else
    v9968_backend_out(port,value);
#endif
}
uint8_t v9968_in(uint8_t port) {
#ifdef LIBV9968_MSX
    return z80_inp(port);
#else
    return v9968_backend_in(port);
#endif
}
void v9968_stream(uint8_t port,const uint8_t *data,uint16_t count) {
#ifdef LIBV9968_MSX
    uint8_t n;
    while(count) {n=count>255?255:(uint8_t)count;z80_otir(data,port,n);data+=n;count-=n;}
#else
    while(count--)v9968_out(port,*data++);
#endif
}
void v9968_select(uint8_t base) {
    v9968_control_port=base+1;v9968_palette_port=base+2;v9968_command_port=base+3;
    v9968_external=base==0x88;
}
static void raw_reg(uint8_t port,uint8_t reg,uint8_t value) {
    v9968_out(port,value);v9968_out(port,reg|128);
}
static uint8_t probe(uint8_t port,uint8_t external) {
    uint8_t id,first;
    if(external) {first=v9968_in(port);if((first&128)&&(v9968_in(port)&128))return 255;}
    /* Proven FPGA initialization: unlock BEFORE the R21 identity test. */
    v9968_out(port+3,0);
    raw_reg(port,15,1);id=(v9968_in(port)>>1)&31;
    /* Repeat S1 identification after the official R21 reset, not R21 readback. */
    if(id) {raw_reg(port,21,0);id=(v9968_in(port)>>1)&31;} else id=1;
    raw_reg(port,15,0);return id;
}
uint8_t v9968_detect(uint8_t bios_base) {
    uint8_t internal,external=255;
    if(bios_base!=0x88&&bios_base!=0x98)return V9968_NOT_FOUND;
    internal=probe(bios_base+1,0);
    if((bios_base&0xf0)!=0x80)external=probe(0x89,1);
    v9968_select(external==3?0x88:bios_base);
    v9968_type=external==3?3:internal;
    return v9968_type==3?V9968_OK:V9968_NOT_FOUND;
}
void v9968_unlock(void) {v9968_out(v9968_control_port+3,0);}
void v9968_reg(uint8_t reg,uint8_t value) {raw_reg(v9968_control_port,reg,value);}
uint8_t v9968_status(uint8_t selector) {
    uint8_t result;v9968_reg(15,selector);result=v9968_in(v9968_control_port);v9968_reg(15,0);return result;
}
uint8_t v9968_wait(uint16_t budget,uint8_t blocks) {
    uint16_t remaining=budget;
    if(!budget||!blocks)return V9968_TIMEOUT;
    while(v9968_status(2)&1) {if(!--remaining){if(!--blocks)return V9968_TIMEOUT;remaining=budget;}}
    return V9968_OK;
}
void v9968_screen(uint8_t screen,uint8_t fil) {
    v9968_unlock();v9968_reg(1,0);v9968_reg(21,0x3a);
    v9968_reg(0,screen==7?0x0a:6);v9968_reg(2,screen==7?0x3f:0x1f);
    v9968_reg(7,0);v9968_reg(8,0x0a);v9968_reg(9,fil?0x84:0x80);
    v9968_reg(20,fil==V9968_FIL_NATIVE?0x31:0x11);
    v9968_reg(21,fil==V9968_FIL_OPENMSX?0x7a:0x3a);
    v9968_reg(18,0);v9968_reg(23,0);v9968_reg(25,0);v9968_reg(26,0);v9968_reg(27,0);
}
void v9968_palette(const uint8_t *rgb,uint8_t first,uint8_t count) {
    v9968_reg(16,first);v9968_stream(v9968_palette_port,rgb,(uint16_t)count*3);
}
void v9968_command(const uint8_t *packet,uint8_t first,uint8_t count) {
    v9968_reg(17,first);v9968_stream(v9968_command_port,packet,count);
}
void v9968_vram_address(uint32_t address,uint8_t writing) {
    v9968_reg(14,(uint8_t)((address>>14)&15));v9968_out(v9968_control_port,(uint8_t)address);
    v9968_out(v9968_control_port,(uint8_t)((address>>8)&63)|(writing?64:0));
}
void v9968_vram_write(const uint8_t *data,uint16_t count) {v9968_stream(v9968_control_port-1,data,count);}
void v9968_vram_read(uint8_t *data,uint16_t count) {while(count--)*data++=v9968_in(v9968_control_port-1);}

