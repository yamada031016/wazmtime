const std = @import("std");

// LEB128でエンコーディングされたバイナリをデコードし、デコードの数値を返却する
pub fn decodeLEB128(data: []u8) usize {
    var num: usize = undefined;
    var decoded_number: usize = 0;
    for (data, 0..) |value, i| {
        num = value & 0b0111_1111; // 値の下位7bit
        decoded_number |= num << @intCast(i * 7); // 128倍して加える

        if (value >> 7 == 0) {
            // 上位1bitが0ならデコード終了
            break;
        }
    }
    return decoded_number;
}

test "decoding by LEB128" {
    // 0x07以降はデコードされない
    var target = [_]u8{ 0xea, 0x09, 0x07, 0x69 };
    const decoded_number = decodeLEB128(&target);
    try std.testing.expect(decoded_number == 1258);
}
