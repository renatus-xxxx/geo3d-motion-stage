#ifndef LIBV9968_GEO3D_H
#define LIBV9968_GEO3D_H
#include "v9968.h"
#ifdef LIBV9968_MSX
#define GEO3D_FAST __z88dk_fastcall
#else
#define GEO3D_FAST
#endif
#ifdef __cplusplus
extern "C" {
#endif
typedef struct { int16_t x,y,z; } geo3d_vertex;
typedef struct { int16_t x,y,z; uint8_t flags; } geo3d_projected;
extern uint8_t geo3d_index_port, geo3d_data_port;
/* Attach after selecting a VDP; select a different device only while idle. */
void geo3d_attach(void);
uint8_t geo3d_probe(void);
void geo3d_index(uint8_t value) GEO3D_FAST;
void geo3d_byte(uint8_t value) GEO3D_FAST;
void geo3d_word(int16_t value) GEO3D_FAST;
uint8_t geo3d_read(void);
uint8_t geo3d_status(void);
void geo3d_reg(uint8_t reg, uint8_t value);
void geo3d_stream(const uint8_t *data, uint16_t count);
uint8_t geo3d_wait(uint16_t budget, uint8_t blocks);
/* Matrix Q2.14; translation/model coordinates signed 16-bit integer. */
void geo3d_matrix(const int16_t *matrix, const geo3d_vertex *translation);
void geo3d_camera(uint16_t focal, int16_t cx, int16_t cy,
                  uint16_t near_z, uint16_t width, uint16_t height);
void geo3d_vertices(const geo3d_vertex *vertices, uint8_t count);
void geo3d_faces(const uint8_t *faces, uint8_t count);
uint8_t geo3d_project(const geo3d_vertex *vertex, geo3d_projected *result);
void geo3d_run(uint8_t vertices, uint8_t faces, uint16_t destination_y, uint8_t mode);
#ifdef __cplusplus
}
#endif
#endif
