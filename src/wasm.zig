const std = @import("std");
const leb128 = @import("leb128.zig");

pub const WasmError = error{
    SectionNotFound,
};

const WasmSection = enum(u4) {
    const Self = @This();

    Custom = 0,
    Type = 1,
    Import = 2,
    Function = 3,
    Table = 4,
    Memory = 5,
    Global = 6,
    Export = 7,
    Start = 8,
    Element = 9,
    Code = 10,
    Data = 11,
    DataCount = 12,

    pub fn init(id: usize) Self {
        return @enumFromInt(id);
    }

    pub fn asText(self: WasmSection) []const u8 {
        return switch (self) {
            .Custom => "custom section",
            .Type => "type section",
            .Import => "import section",
            .Function => "function section",
            .Table => "table section",
            .Memory => "memory section",
            .Global => "global section",
            .Export => "export section",
            .Start => "start section",
            .Element => "element section",
            .Code => "code section",
            .Data => "data section",
            .DataCount => "data count section",
        };
    }
};

// Wasmの解析を行う主体となる関数
pub fn analyzeWasm(data: []u8, size: usize, file_path: []const u8) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{s}\t\tWasm version 0x{x}\n\n", .{ file_path, data[4] });
    std.debug.print("35:{x}", .{data[8 + 35]});

    // var section_size: usize = 0;
    // wasmのバイナリフォーマットのmagicナンバーやバージョン(8 bytes)を省いた位置を初期位置とする
    var pos: usize = 8;
    for (0..13) |id| {
        if (getSectionSize(data, size, id, pos)) |section_struct| {
            pos += section_struct.size + 1 + section_struct.byte_width;
            try stdout.print("({d:0>2}) {s}\tsize: {d:0>2} bytes\n", .{ id, WasmSection.init(id).asText(), section_struct.size });
        } else |err| {
            switch (err) {
                WasmError.SectionNotFound => {
                    try stdout.print("({d:0>2}) {s}\tsize: {d:0>2} bytes\n", .{ id, WasmSection.init(id).asText(), 0 });
                },
                else => unreachable,
            }
        }
    }
    try bw.flush();
}

const WasmSectionSize = struct {
    size: usize,
    byte_width: usize,
};

// idで指定されたセクションのサイズを取得
// wasm binaryではidの次の数値がサイズを表している. 1-4bytes幅で可変長
// posはsection idの位置を想定している
// data: Wasm binary, max: wasm binary size, id: section id (0-12)
// pos: starting position for reading wasm binary
pub fn getSectionSize(data: []u8, max: usize, id: usize, pos: usize) WasmError!WasmSectionSize {
    var section_size = WasmSectionSize{ .size = 0, .byte_width = 0 };
    for (data[pos..], pos..) |value, i| {
        _ = value;
        if (i == max) {
            break;
        }

        if (id == data[pos]) {
            const s = get_section_size: {
                var tmp = [_]u8{0} ** 4;
                for (data[i + 1 ..], 0..) |val, j| {
                    tmp[j] = val;
                    if (val < 128) {
                        section_size.byte_width = j + 1;
                        break;
                    }
                }
                break :get_section_size &tmp;
            };
            section_size.size = leb128.decodeLEB128(@constCast(s));
            return section_size;
        } else {
            return WasmError.SectionNotFound;
        }
    }
    return WasmError.SectionNotFound;
}
