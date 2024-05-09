pub const Instr = enum(u32) {
    Block = 0x02,
    Loop = 0x03,
    If = 0x04,
    IfElse = 0x05,
    End = 0x0B,
    Br = 0x0C,
    BrIf = 0x0D,
    BrTable = 0x0E,
    Return = 0x0F,
    Call = 0x10,
    CallIndirect = 0x11,
    RefNull = 0xD0,
    RefIsNull = 0xD1,
    RefFunc = 0xD2,
    Drop = 0x1A,
    Select = 0x1B,
    SelectVec = 0x1C,
    LocalGet = 0x20,
    LocalSet = 0x21,
    LocalTee = 0x22,
    GlobalGet = 0x23,
    GlobalSet = 0x24,
    TableGet = 0x25,
    TableSet = 0x26,
    Fc = 0xFC,
    I32Load = 0x28,
    I64Load = 0x29,
    F32Load = 0x2a,
    F64Load = 0x2b,
    I32Load8S = 0x2c,
    I32Load8U = 0x2d,
    I32Load16S = 0x2e,
    I32Load16U = 0x2f,
    I64Load8S = 0x30,
    I64Load8U = 0x31,
    I64Load16S = 0x32,
    I64Load16U = 0x33,
    I64Load32S = 0x34,
    I64Load32U = 0x35,
    I32Store = 0x36,
    I64Store = 0x37,
    F32Store = 0x38,
    F64Store = 0x39,
    I32Store8 = 0x3a,
    I32Store16 = 0x3b,
    I64Store8 = 0x3c,
    I64Store16 = 0x3d,
    I64Store32 = 0x3e,
    MemorySize = 0x3f_00, // 0x3f 0x00
    MemoryGrow = 0x40_00, // 0x40 0x00
    I32Const = 0x41,
    I64Const = 0x42,
    F32Const = 0x43,
    F64Const = 0x44,
    I64Add = 0x7C,
};

pub const FcInstr = enum(u32) {
    MemoryInit = 8,
    DataDrop = 9,
    MemoryCopy = 10,
    MemoryFill = 11,
    TableInit = 12,
    ElemDrop = 13,
    TableCopy = 14,
    TableGrow = 15,
    TableSize = 16,
    TableFill = 17,
};
