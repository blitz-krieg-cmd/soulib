// zig cc read_dcx.c -lc -L../zig-out/lib/ -I../include/ -lsoulib -o read_dcx_c.exe

#include "soulib.h"
#include "stdio.h"

int main(int argc, char const *argv[])
{
    DCX_C dcx = parseDCX("E:/dev/soulib/dsr/msg/ENGLISH/item.msgbnd.dcx");
    printf("%d", dcx.uncompressedSize);
    return 0;
}
