# Souls Lib (Soulib)

Currently a very WIP library being created slowly in my free time. Feel free to contribute but I don't have any clear direction on how I want this project to be structured so please be mindful of that. If you have any questions feel free to ask them.

## Design of the library

Rough summary of using the library:
    *Open file using it's path.
    *Read all bytes from file.
    *Pass file bytes to library and parse.

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
❌ Incomplete |  BHD5 | .bhd, .bhd5 | The header file for the large primary file archives used by most games
❌ Incomplete |  BND3 | .\*bnd | A general-purpose file container used before DS2
❌ Incomplete  |  BTAB | .btab | Controls lightmap atlasing
❌ Incomplete  |  BTL | .btl | Configures point light sources
❌ Incomplete  |  BTPB | .btpb | Contains baked light probes for a map
❌ Incomplete  |  BXF3 | .\*bhd + .\*bdt | Equivalent to BND3 but with a separate header and data file
❌ Incomplete  |  CCM | .ccm | Determines font layout and texture mapping
❌ Incomplete  |  CLM2 | .clm | A FLVER companion format that has something to do with cloth
✏️ Working  |  DCX | .dcx | A simple wrapper for a single compressed file
❌ Incomplete |  DRB | .drb | Controls GUI layout and styling
❌ Incomplete |  EDD | .edd | An ESD companion format that gives friendly names for various elements
❌ Incomplete |  EMELD | .eld, .emeld | Stores friendly names for EMEVD events
❌ Incomplete |  EMEVD | .evd, .emevd | Event scripts
❌ Incomplete |  ENFL | .entryfilelist | Specifies assets to preload when going through a load screen
❌ Incomplete |  ESD | .esd | Defines a set of state machines used to control characters, menus, dialog, and/or map events
❌ Incomplete |  F2TR | .flver2tri | A FLVER companion format that links the vertices to the FaceGen system
❌ Incomplete |  FLVER | .flv, .flver | FromSoftware's standard 3D model format
❌ Incomplete |  FMG | .fmg | A collection of strings with corresponding IDs used for most game text
❌ Incomplete |  GPARAM | .fltparam, .gparam | A generic graphics configuration format
❌ Incomplete |  GRASS | .grass | Specifies meshes for grass to be dynamically placed on
❌ Incomplete |  LUAGNL | .luagnl | A list of global variable names for Lua scripts
❌ Incomplete |  LUAINFO | .luainfo | Information about AI goals for Lua scripts
❌ Incomplete |  MCG | .mcg | A high-level navigation format used in DeS and DS1
❌ Incomplete |  MCP | .mcp | Another high-level navigation format used in DeS and DS1
❌ Incomplete |  MSB | .msb | The main map format, listing all enemies, collisions, trigger volumes, etc
❌ Incomplete |  MTD | .mtd | Defines some material and shader properties; referenced by FLVER materials
❌ Incomplete |  NVM | .nvm | The navmesh format used in DeS and DS1
❌ Incomplete |  PARAM | .param | A generic configuration format
❌ Incomplete |  PARAMDEF | .def, .paramdef | A companion format that specifies the format of data in a param
❌ Incomplete |  PARAMTDF | .tdf | A companion format that provides friendly names for enumerated types in params
❌ Incomplete |  RMB | .rmb | Controller rumble effects for all games
❌ Incomplete |  TPF | .tpf | A container for platform-specific texture data

## Examples Building

To run examples:  
`zig build read_dcx -- "E:/SteamLibrary/steamapps/common/DARK SOULS REMASTERED/msg/ENGLISH/item.msgbnd.dcx"`
