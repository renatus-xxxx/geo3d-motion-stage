#include <stdio.h>
#include "psg.h"
#ifdef MOTION_NATIVE
volatile unsigned char paused,demo_wait,music_fade;
extern volatile unsigned char music_enabled,music_restart;
void music_init(void);
#else
volatile unsigned char paused,demo_wait,music_fade;
extern volatile unsigned char music_enabled,music_restart;
__sfr __at(0x2f) marker;
__sfr __at(0xa0) address;
__sfr __at(0xa1) data;
void music_init(void);
#endif
void music_tick(void);
#ifdef MOTION_NATIVE
static unsigned char selected;
static unsigned long trace_hash=2166136261UL;
static int print_trace;
void psg_select(unsigned char reg){selected=reg;}
unsigned char psg_read(void){return selected==7?0x80:0;}
void psg_write(unsigned char reg,unsigned char value){if(print_trace)printf("%02x %02x\n",reg,value);trace_hash=((trace_hash^reg)*16777619UL)&0xffffffffUL;trace_hash=((trace_hash^value)*16777619UL)&0xffffffffUL;}
int main(int argc,char **argv){
(void)argv;print_trace=argc>1;
#else
void main(void){
#endif
unsigned int t;
#ifndef MOTION_NATIVE
__asm di __endasm;
address=7;data=0x80;marker=0x55;
#endif
music_init();
for(t=0;t<1100;t++) {
paused=t>=960&&t<975;demo_wait=t>=975&&t<990;
music_fade=t>=1000&&t<1032?(unsigned char)(t-1000):0;
if(t==990)music_enabled=0;if(t==999)music_enabled=1;
if(t==1033)music_restart=1;
music_tick();
}
#ifndef MOTION_NATIVE
marker=0xaa;while(1){}
#else
if(!print_trace)printf("MSX PSG oracle: %08lx\n",trace_hash);return trace_hash==0x29a55784UL?0:1;
#endif
}
