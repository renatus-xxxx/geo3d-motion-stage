#include "geo3d.h"
#ifdef LIBV9968_MSX
#pragma disable_warning 85
#endif
#ifndef LIBV9968_MSX
extern void geo3d_backend_index(uint8_t value);
extern void geo3d_backend_write(uint8_t value);
extern uint8_t geo3d_backend_read(void);
extern uint8_t geo3d_backend_status(void);
#endif
uint8_t geo3d_index_port=0x9d,geo3d_data_port=0x9f;
void geo3d_attach(void) {geo3d_index_port=v9968_control_port+4;geo3d_data_port=v9968_control_port+6;}
#ifdef LIBV9968_MSX
void geo3d_index(uint8_t value) GEO3D_FAST __naked {
#asm
 ld a,(_geo3d_index_port)
 ld c,a
 out (c),l
 ret
#endasm
}
void geo3d_byte(uint8_t value) GEO3D_FAST __naked {
#asm
 ld a,(_geo3d_data_port)
 ld c,a
 out (c),l
 ret
#endasm
}
void geo3d_word(int16_t value) GEO3D_FAST __naked {
#asm
 ld a,(_geo3d_data_port)
 ld c,a
 out (c),l
 out (c),h
 ret
#endasm
}
#else
void geo3d_index(uint8_t value) {geo3d_backend_index(value);}
void geo3d_byte(uint8_t value) {geo3d_backend_write(value);}
void geo3d_word(int16_t value) {geo3d_byte((uint8_t)value);geo3d_byte((uint8_t)((uint16_t)value>>8));}
#endif
uint8_t geo3d_status(void) {
#ifdef LIBV9968_MSX
 return v9968_in(geo3d_index_port);
#else
 return geo3d_backend_status();
#endif
}
uint8_t geo3d_read(void) {
#ifdef LIBV9968_MSX
 return v9968_in(geo3d_data_port);
#else
 return geo3d_backend_read();
#endif
}
void geo3d_reg(uint8_t reg,uint8_t value) {geo3d_index(reg);geo3d_byte(value);}
void geo3d_stream(const uint8_t *data,uint16_t count) {
#ifdef LIBV9968_MSX
 v9968_stream(geo3d_data_port,data,count);
#else
 while(count--)geo3d_byte(*data++);
#endif
}
uint8_t geo3d_probe(void) {
    uint8_t saved,ok;geo3d_attach();geo3d_index(0x44);saved=geo3d_read();
    geo3d_reg(0x44,0x55);geo3d_index(0x44);ok=geo3d_read()==0x55;
    geo3d_reg(0x44,0xaa);geo3d_index(0x44);ok&=geo3d_read()==0xaa;
    geo3d_reg(0x44,saved);return ok?V9968_OK:V9968_NO_GEO;
}
uint8_t geo3d_wait(uint16_t budget,uint8_t blocks) {
    uint16_t remaining=budget;if(!budget||!blocks)return V9968_GEO_TIMEOUT;
    while(geo3d_status()&1) {if(!--remaining){if(!--blocks)return V9968_GEO_TIMEOUT;remaining=budget;}}
    return V9968_OK;
}
void geo3d_matrix(const int16_t *m,const geo3d_vertex *t) {
    uint8_t i;geo3d_index(0);for(i=0;i<9;i++)geo3d_word(m[i]);
    geo3d_word(t->x);geo3d_word(t->y);geo3d_word(t->z);
}
void geo3d_camera(uint16_t f,int16_t cx,int16_t cy,uint16_t nz,uint16_t w,uint16_t h) {
    geo3d_index(24);geo3d_word(f);geo3d_word(cx);geo3d_word(cy);geo3d_word(nz);geo3d_word(w);geo3d_word(h);
}
void geo3d_vertices(const geo3d_vertex *v,uint8_t count) {
    uint8_t i;geo3d_reg(0x40,0);geo3d_index(0x50);
    for(i=0;i<count;i++){geo3d_word(v[i].x);geo3d_word(v[i].y);geo3d_word(v[i].z);}
}
void geo3d_faces(const uint8_t *f,uint8_t count) {geo3d_reg(0x58,0);geo3d_index(0x52);geo3d_stream(f,(uint16_t)count*11);}
static int16_t read_word(void) {uint16_t lo=geo3d_read();return (int16_t)(lo|((uint16_t)geo3d_read()<<8));}
uint8_t geo3d_project(const geo3d_vertex *v,geo3d_projected *p) {
    geo3d_index(36);geo3d_word(v->x);geo3d_word(v->y);geo3d_word(v->z);
    if(geo3d_wait(65535,1))return V9968_GEO_TIMEOUT;
    geo3d_index(48);p->x=read_word();p->y=read_word();p->z=read_word();p->flags=geo3d_read();return V9968_OK;
}
void geo3d_run(uint8_t nv,uint8_t nf,uint16_t y,uint8_t mode) {
    geo3d_reg(0x42,nv);geo3d_reg(0x59,nf);geo3d_index(0x46);geo3d_word(y);geo3d_reg(0x48,mode);
}
