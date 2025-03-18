#include "stdint.h"

#pragma once

// #ifdef __cplusplus
// extern "C" {
// #endif

typedef struct  {
    uint8_t dcx[4]; 
    int32_t dcsOffset;
    int32_t dcpOffset; 
    uint8_t dcs[4]; 
    uint32_t uncompressedSize;
    uint32_t compressedSize;
    uint8_t dcp[4]; 
    uint8_t format[4];
    uint8_t dca[4]; 
    int32_t dcaSize;

    uint8_t data[];
} DCX_C;

extern DCX_C parseDCX(char *path);

// #ifdef __cplusplus
// };
// #endif