#include "stage.h"
/* Quarter-wave symmetry preserves all 256 original Q2.14 values. */
static const int quarter_sine[65] = {
    0,     402,   804,   1205,  1606,  2006,  2404,  2801,  3196,  3590,  3981,  4370,  4756,
    5139,  5520,  5897,  6270,  6639,  7005,  7366,  7723,  8076,  8423,  8765,  9102,  9434,
    9760,  10080, 10394, 10702, 11003, 11297, 11585, 11866, 12140, 12406, 12665, 12916, 13160,
    13395, 13623, 13842, 14053, 14256, 14449, 14635, 14811, 14978, 15137, 15286, 15426, 15557,
    15679, 15791, 15893, 15986, 16069, 16143, 16207, 16261, 16305, 16340, 16364, 16379, 16384};
int trig_sine(unsigned char angle) __z88dk_fastcall {
    unsigned char index = angle & 63;
    int value;
    if (angle & 64)
        index = 64 - index;
    value = quarter_sine[index];
    return angle & 128 ? -value : value;
}
