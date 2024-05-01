const STACK_SIZE = 1024;

pub const Wasm = struct {
    const Self = @This();
    const Instruction = ?*const fn (*Self) void;
    var instructions: [256]Instruction = [_]Instruction{null} ** 256;
};
pub const Stack = struct {
    var stack: [STACK_SIZE]i64 = undefined;
    var top: usize = 0;

    pub fn init() *Stack {
        return @constCast(&Stack{});
    }

    pub fn push(self: *Stack, value: anytype) void {
        _ = self;
        top += 1;
        stack[top] = @as(i64, @intCast(value));
    }
    pub fn pop(self: *Stack) i64 {
        _ = self;
        const value = stack[top];
        top -= 1;
        return value;
    }
};
