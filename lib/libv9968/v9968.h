#ifndef LIBV9968_H
#define LIBV9968_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* A single selected device. All coordinates and words have MSX widths. */
typedef uint8_t v9968_u8;
typedef uint16_t v9968_u16;
enum { V9968_FIL_NONE, V9968_FIL_OPENMSX, V9968_FIL_NATIVE };
enum { V9968_OK, V9968_TIMEOUT, V9968_NOT_FOUND, V9968_GEO_TIMEOUT, V9968_NO_IRQ, V9968_NO_GEO };
extern uint8_t v9968_control_port, v9968_palette_port, v9968_command_port;
extern uint8_t v9968_external, v9968_type;
/* BIOS port base on MSX (98h or 88h); prefer external if detected.
 * Caller owns DI/EI and the interrupt handler. No BIOS screen-mode call. */
uint8_t v9968_detect(uint8_t bios_base);
void v9968_select(uint8_t base);
void v9968_unlock(void);
/* MSX: mask interrupts around register/status/VRAM/stream transactions.
 * status() always restores R15=0; detect() is a startup-only destructive probe.
 * Ports use 8-bit MSX decoding. VRAM addresses wrap within 256 KiB. */
void v9968_reg(uint8_t reg, uint8_t value);
uint8_t v9968_status(uint8_t selector);
uint8_t v9968_wait(uint16_t budget, uint8_t blocks);
void v9968_screen(uint8_t screen, uint8_t fil);
void v9968_palette(const uint8_t *rgb5, uint8_t first, uint8_t count);
void v9968_command(const uint8_t *packet, uint8_t first, uint8_t count);
void v9968_vram_address(uint32_t address, uint8_t writing);
void v9968_vram_write(const uint8_t *data, uint16_t count);
void v9968_vram_read(uint8_t *data, uint16_t count);
/* Raw transport is useful for existing command streams; no drawing policy. */
void v9968_out(uint8_t port, uint8_t value);
uint8_t v9968_in(uint8_t port);
void v9968_stream(uint8_t port, const uint8_t *data, uint16_t count);
#ifdef __cplusplus
}
#endif
#endif
