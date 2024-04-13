const std = @import("std");

pub fn readFileAll(path: []const u8, buf: []u8) !usize {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    return try reader.readAll(@constCast(buf));
}
