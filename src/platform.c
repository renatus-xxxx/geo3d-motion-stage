#include "stage.h"

unsigned char platform_r800;

/* BIOS page 0 remains mapped by the cartridge loader. MSXVER is the
 * BIOS generation byte, not the VDP ID (our VDP is an extension). */
void platform_init(void) {
    platform_r800 = 0;
    if (*(const unsigned char *)0x002d != 3)
        return;
    if (*(const unsigned char *)0x0180 != 0xc3)
        return;
    // clang-format off
#asm
    EXTERN msxbios
    push ix
    ld a,0x82
    ld ix,0x0180
    call msxbios
    pop ix
#endasm
            // clang-format on
            platform_r800 = 1;
}
