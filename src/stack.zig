const STACK_SIZE = 1024;

const CurrentTopStack = enum {
    f64,
    f32,
    i64,
    u64,
};

pub const Stack = struct {
    const f64stack = @constCast(&(_Stack(f64)));
    const f32stack = @constCast(&(_Stack(f32)));
    const i64stack = @constCast(&(_Stack(i64)));
    const u64stack = @constCast(&(_Stack(u64)));
    var top: CurrentTopStack = undefined;

    pub fn init() *Stack {
        var stack = Stack{};
        return @constCast(&stack);
    }

    pub fn push(self: *Stack, comptime T: type, value: T) void {
        _ = self;

        switch (T) {
            f64 => {
                f64stack.push(value);
                top = .f64;
            },
            f32 => {
                f32stack.push(value);
                top = .f32;
            },
            i64 => {
                i64stack.push(value);
                top = .i64;
            },
            u64 => {
                u64stack.push(value);
                top = .u64;
            },
            else => unreachable,
        }
    }

    pub fn pop(self: *Stack, comptime T: type) T {
        _ = self;
        const value = switch (T) {
            f64 => f64stack.pop(),
            f32 => f32stack.pop(),
            i64 => i64stack.pop(),
            u64 => u64stack.pop(),
            void => {
                switch (top) {
                    .f64 => @import("std").debug.print("pop value: {}\n", .{f64stack.pop()}),
                    .f32 => @import("std").debug.print("pop value: {}\n", .{f32stack.pop()}),
                    .i64 => @import("std").debug.print("pop value: {}\n", .{i64stack.pop()}),
                    .u64 => @import("std").debug.print("pop value: {}\n", .{u64stack.pop()}),
                }
                return;
            },
            else => unreachable,
        };
        return value;
    }
};

fn _Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        var stack: [STACK_SIZE]T = undefined;
        var top: usize = 0;

        pub fn push(value: T) void {
            top += 1;
            stack[top] = value;
        }
        pub fn pop() T {
            const value = stack[top];
            top -= 1;
            return value;
        }
    };
}
