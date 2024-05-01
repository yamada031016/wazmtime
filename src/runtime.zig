const Stack = @import("stack.zig").Stack;
const Instr = @import("instr.zig").Instr;

pub const Runtime = struct {
    const Self = @This();
    const Instruction = ?*const fn (*Self) void;
    var instructions: [256]Instruction = [_]Instruction{null} ** 256;
    var instr_pos = 0;
    var nest_block_cnt = 0;

    var stack: *Stack = undefined;
    var args_width = 0;

    data: []u8,

    pub fn init(data: []u8) Self {
        var runtime = Self{ .data = data };
        stack = Stack.init();
        runtime.setInstructions();

        return runtime;
    }

    fn execute(self: *Runtime, end_pos: usize) void {
        for (self.data[instr_pos .. end_pos + 1], instr_pos..end_pos + 1) |instr, i| {
            if (args_width > 0) {
                // 引数はスキップする
                args_width -= 1;
                continue;
            }

            switch (instr) {
                .Block => self.block(i),
                .I64Const => self.i64_const(i),
                .I64Add => self.i64_add(),
                .Drop => self.drop(),
                else => unreachable,
            }
        }
    }

    fn block(self: *Stack, pos: usize) void {
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

    fn i64_const(self: *Stack, pos: usize) void {
        args_width = calcArgsWidth(self.data, pos + 1, 8);
        self.push(self.data[pos + 1]);
    }

    fn i64_add(self: *Stack) void {
        args_width = 1; //valtype
        const a = self.pop();
        const b = self.pop();
        self.push(a + b);
    }

    fn drop(self: *Stack) void {
        self.pop();
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
