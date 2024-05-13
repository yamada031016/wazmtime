const Stack = @import("stack.zig").Stack;
const Instr = @import("instr.zig").Instr;
const std = @import("std");

pub const Runtime = struct {
    const Self = @This();

    var nest_block_cnt: usize = 0;
    var args_width: usize = 0;

    data: []u8,
    stack: *Stack = undefined,

    pub fn init(data: []u8) *Self {
        return @constCast(&Self{ .data = data, .stack = Stack.init() });
    }

    pub fn execute(self: *Runtime, target: []u8) !void {
        for (target, 0..) |instr_code, i| {
            if (args_width > 0) {
                // 引数はスキップする
                args_width -= 1;
                continue;
            }
            std.debug.print("instr:{x}\n", .{instr_code});
            const instr = @as(Instr, @enumFromInt(instr_code));
            switch (instr) {
                .Unreachable => unreachable,
                .Block => self.block(target, i + 1),
                .I64Const => self.def_const(i64, target, i + 1),
                .I64Add => self.add(i64),
                .F64Const => self.def_const(f64, target, i + 1),
                .F64Add => self.add(f64),
                .F64Mul => self.mul(f64),
                .Drop => self.drop(),
                .I64Sub => self.sub(i64),
                .I64Mul => self.mul(i64),
                .I64DivS => try self.divS(i64),
                .I64DivU => try self.divU(i64),
                .I64RemS => try self.remS(i64),
                .I64RemU => try self.remU(i64),
                .End => return,
                else => {},
            }
        }
    }

    fn block(self: *Self, target: []u8, pos: usize) void {
        _ = self;
        nest_block_cnt += 1;
        switch (target[pos]) {
            0x40 => args_width = 1,
            0x7E, 0x7D, 0x7C, 0x7B, 0x70, 0x6F => args_width = 1, //valtype
            else => {
                //s33
                const n = target[pos + calcArgsWidth(target, pos, 4)];
                if (n < (2 << 6)) {
                    args_width = calcArgsWidth(target, pos, 4);
                } else if (2 << 6 <= n and n < 2 << 7) {
                    args_width = calcArgsWidth(target, pos, 4);
                } else if (n >= 2 << 7) {
                    args_width = calcArgsWidth(target, pos, 4);
                }
                args_width = calcArgsWidth(target, pos, 4);
                if (args_width > @ceil(33.0 / 7.0)) {
                    args_width = @ceil(33.0 / 7.0);
                }
            },
        }
    }

    fn def_const(self: *Self, comptime T: type, target: []u8, pos: usize) void {
        const num = proc: {
            switch (T) {
                f64, f32 => {
                    args_width = 8;
                    var flt: u64 = 0;
                    for (0..8) |i| {
                        flt |= @as(u64, @intCast(target[pos + (7 - i)])) << @as(u6, @truncate(((7 - i) * 8)));
                    }
                    break :proc @as(T, @bitCast(flt));
                },
                else => {
                    args_width = calcArgsWidth(target, pos, 8);
                    break :proc @import("leb128.zig").decodesLEB128(target[pos..]);
                },
            }
        };
        self.stack.push(T, num);
        std.debug.print("push value: {}\n", .{num});
    }

    fn add(self: *Self, comptime T: type) void {
        const a = @as(T, @bitCast(self.stack.pop(T)));
        const b = @as(T, @bitCast(self.stack.pop(T)));
        self.stack.push(T, b + a);
        std.debug.print("a: {}\tb: {}\n", .{ b, a });
    }

    fn sub(self: *Self, comptime T: type) void {
        const a = @as(T, @bitCast(self.stack.pop(T)));
        const b = @as(T, @bitCast(self.stack.pop(T)));
        self.stack.push(T, b - a);
        std.debug.print("a: {}\tb: {}\n", .{ b, a });
    }

    fn mul(self: *Self, comptime T: type) void {
        const a = @as(T, @bitCast(self.stack.pop(T)));
        const b = @as(T, @bitCast(self.stack.pop(T)));
        self.stack.push(T, b * a);
        std.debug.print("a: {}\tb: {}\n", .{ b, a });
    }

    fn divS(self: *Self, comptime T: type) !void {
        const denomitor = @as(T, @bitCast(self.stack.pop(T)));
        const numerator = @as(T, @bitCast(self.stack.pop(T)));
        const res = try std.math.divTrunc(isize, numerator, denomitor);
        self.stack.push(T, res);
        std.debug.print("a: {}\tb: {}\n", .{ numerator, denomitor });
    }

    fn divU(self: *Self, comptime T: type) !void {
        const denomitor = @as(u64, @bitCast(self.stack.pop(T)));
        const numerator = @as(u64, @bitCast(self.stack.pop(T)));
        const res = try std.math.divTrunc(u64, numerator, denomitor);
        self.stack.push(u64, @abs(res));
        std.debug.print("a: {}\tb: {}\n", .{ numerator, denomitor });
    }

    fn remS(self: *Self, comptime T: type) !void {
        const denomitor = @as(T, @bitCast(self.stack.pop(T)));
        const numerator = @as(T, @bitCast(self.stack.pop(T)));
        const res = try std.math.rem(i64, numerator, denomitor);
        self.stack.push(T, res);
        std.debug.print("a: {}\tb: {}\n", .{ numerator, denomitor });
    }

    fn remU(self: *Self, comptime T: type) !void {
        const denomitor = @as(u64, @bitCast(self.stack.pop(T)));
        const numerator = @as(u64, @bitCast(self.stack.pop(T)));
        const res = try std.math.mod(u64, numerator, denomitor);
        self.stack.push(u64, res);
        std.debug.print("a: {}\tb: {}\n", .{ numerator, denomitor });
    }

    fn drop(self: *Self) void {
        self.stack.pop(void);
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
