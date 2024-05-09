const Stack = @import("stack.zig").Stack;
const Instr = @import("instr.zig").Instr;
const std = @import("std");

pub const Runtime = struct {
    const Self = @This();

    var nest_block_cnt: usize = 0;
    var args_width: usize = 0;

    data: []u8,
    stack: *Stack = undefined,

    pub fn init(data: []u8) Self {
        return Self{ .data = data, .stack = Stack.init() };
    }

    pub fn execute(self: *Runtime, first_pos: usize) void {
        for (self.data[first_pos..], first_pos..) |instr_code, i| {
            if (args_width > 0) {
                // 引数はスキップする
                args_width -= 1;
                continue;
            }
            switch (instr_code) {
                @intFromEnum(Instr.Block) => self.block(i),
                @intFromEnum(Instr.I64Const) => self.i64_const(i),
                @intFromEnum(Instr.I64Add) => self.i64_add(),
                @intFromEnum(Instr.Drop) => self.drop(),
                @intFromEnum(Instr.End) => return,
                else => {},
            }
        }
    }

    fn block(self: *Self, pos: usize) void {
        nest_block_cnt += 1;
        switch (self.data[pos + 1]) {
            0x40 => args_width = 1,
            0x7E, 0x7D, 0x7C, 0x7B, 0x70, 0x6F => args_width = 1, //valtype
            else => {
                //s33
                const n = self.data[pos + 1 + calcArgsWidth(self.data, pos + 1, 4)];
                if (n < (2 << 6)) {
                    args_width = calcArgsWidth(self.data, pos + 1, 4);
                } else if (2 << 6 <= n and n < 2 << 7) {
                    args_width = calcArgsWidth(self.data, pos + 1, 4);
                } else if (n >= 2 << 7) {
                    args_width = calcArgsWidth(self.data, pos + 1, 4);
                }
                args_width = calcArgsWidth(self.data, pos + 1, 4);
                if (args_width > @ceil(33.0 / 7.0)) {
                    args_width = @ceil(33.0 / 7.0);
                }
            },
        }
    }

    fn i64_const(self: *Self, pos: usize) void {
        args_width = calcArgsWidth(self.data, pos + 1, 8);
        self.stack.push(self.data[pos + 1]);
        std.debug.print("push value: {}\n", .{self.data[pos + 1]});
    }

    fn i64_add(self: *Self) void {
        const a = self.stack.pop();
        const b = self.stack.pop();
        self.stack.push(a + b);
        std.debug.print("a: {}\tb: {}\n", .{ a, b });
    }

    fn drop(self: *Self) void {
        // _ = self.stack.pop();
        std.debug.print("pop value: {}\n", .{self.stack.pop()});
    }

    fn calcArgsWidth(data: []u8, pos: usize, comptime byte_width: usize) usize {
        var tmp = [_]u8{0} ** byte_width;
        var width: usize = 0;
        for (data[pos .. pos + byte_width], 0..byte_width) |val, j| {
            if (val < 128) {
                tmp[j] = val;
                width = j + 1;
                break;
            }
            tmp[j] = val;
            width = j + 1;
        }
        return width;
    }
};
