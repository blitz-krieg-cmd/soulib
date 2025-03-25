# Souls Lib (Soulib)

> Currently a very WIP library being created slowly in my free time. Feel free to contribute but I don't have any clear direction on how I want this project to be structured so please be mindful of that. If you have any questions feel free to ask them.

## Goals

- Zig Library
- C ABI Library from Zig
- All recent common fromsoft formats (excluding older titles. anything prior ds1-ptde)

## Design of the library

Rough summary of using the library:

- Open file using it's path.
- Read all bytes from file.
- Pass file bytes to library and parse.

## Example Usage

```zig
const std = @import("std");
// Import the library.
const soulib = @import("soulib");

pub fn main() !void {
    // Define the allocator to use.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Define the file to parse over.
    const path = "path/to/dcx/file.dcx";
    var file = std.fs.openFileAbsolute(
        path,
        .{ .mode = .read_only },
    ) catch unreachable;
    defer file.close();

    // Read the bytes from the file.
    const fileBytes = try file.readToEndAlloc(allocator, try file.getEndPos());

    // Parse the file.
    const dcx = try soulib.DCX.read(
        allocator,
        fileBytes,
    );
    
    // Use the parsed data.
    std.debug.print("HEADER:\n    Magic: {c}\n    Compression Type: {c}\n    Compressed size: {d}\n    Decompressed size: {d}\nBODY:\n    Length: {d}\n    Summary: {x}", .{
        dcx.header.dcx,
        dcx.header.format,
        dcx.header.compressedSize,
        dcx.header.uncompressedSize,
        dcx.data.len,
        dcx.data[0..32],
    });
}
```

## Formats

Basic descriptions are provided below. Checkmarks show library progress on file type.

State | Format | Extension | Description
------ | ------ | --------- | -----------
✏️ |  DCX | .dcx | A simple wrapper for a single compressed file
✏️ |  TPF | .tpf | A container for platform-specific texture data
❌ |  BND3 | .\*bnd | A general-purpose file container used before DS2
❌ |  BHD5 | .bhd, .bhd5 | The header file for the large primary file archives used by most games
❌ |  BTAB | .btab | Controls lightmap atlasing
❌ |  BTL | .btl | Configures point light sources
❌ |  BTPB | .btpb | Contains baked light probes for a map
❌ |  BXF3 | .\*bhd + .\*bdt | Equivalent to BND3 but with a separate header and data file
❌ |  CCM | .ccm | Determines font layout and texture mapping
❌ |  CLM2 | .clm | A FLVER companion format that has something to do with cloth
❌ |  DRB | .drb | Controls GUI layout and styling
❌ |  EDD | .edd | An ESD companion format that gives friendly names for various elements
❌ |  EMELD | .eld, .emeld | Stores friendly names for EMEVD events
❌ |  EMEVD | .evd, .emevd | Event scripts
❌ |  ENFL | .entryfilelist | Specifies assets to preload when going through a load screen
❌ |  ESD | .esd | Defines a set of state machines used to control characters, menus, dialog, and/or map events
❌ |  F2TR | .flver2tri | A FLVER companion format that links the vertices to the FaceGen system
❌ |  FLVER | .flv, .flver | FromSoftware's standard 3D model format
❌ |  FMG | .fmg | A collection of strings with corresponding IDs used for most game text
❌ |  GPARAM | .fltparam, .gparam | A generic graphics configuration format
❌ |  GRASS | .grass | Specifies meshes for grass to be dynamically placed on
❌ |  LUAGNL | .luagnl | A list of global variable names for Lua scripts
❌ |  LUAINFO | .luainfo | Information about AI goals for Lua scripts
❌ |  MCG | .mcg | A high-level navigation format used in DeS and DS1
❌ |  MCP | .mcp | Another high-level navigation format used in DeS and DS1
❌ |  MSB | .msb | The main map format, listing all enemies, collisions, trigger volumes, etc
❌ |  MTD | .mtd | Defines some material and shader properties; referenced by FLVER materials
❌ |  NVM | .nvm | The navmesh format used in DeS and DS1
❌ |  PARAM | .param | A generic configuration format
❌ |  PARAMDEF | .def, .paramdef | A companion format that specifies the format of data in a param
❌ |  PARAMTDF | .tdf | A companion format that provides friendly names for enumerated types in params
❌ |  RMB | .rmb | Controller rumble effects for all games

## Examples Building

> To run examples:  
`zig build read_dcx -Dtarget=x86_64-windows -- "E:/SteamLibrary/steamapps/common/DARK SOULS REMASTERED/msg/ENGLISH/item.msgbnd.dcx"`

## Notes on Testing

The tests in the source look to a Dark Souls Remastered Directory. It should be alongside the build.zig and called "dsr".

- build.zig
- src/
  - root.zig
  - dcx.zig
- dsr/
  - chr/
  - msg/
