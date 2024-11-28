const std = @import("std");
const VStore = @import("Variables.zig").VariableStore;

const SysFormat = enum {
    time,
};

const Parser = struct {
    input: []const u8,
    idx: usize = 0,
    pub const Token = union(enum) {
        format: []const u8,
        text: []const u8,
    };
    pub fn next(self: *Parser) !?Token {
        if (self.idx >= self.input.len) return null;
        if (self.input[self.idx] == '{') {
            if (std.mem.indexOfScalarPos(u8, self.input, self.idx, '}')) |pos| {
                const start = self.idx + 1;
                defer self.idx = pos + 1;
                return .{ .format = self.input[start..pos] };
            } else {
                return error.InvalidString;
            }
        } else {
            const start = self.idx;
            if (std.mem.indexOfScalarPos(u8, self.input, self.idx, '{')) |pos| {
                defer self.idx = pos;
                return .{ .text = self.input[start..pos] };
            } else {
                defer self.idx = self.input.len;
                return .{ .text = self.input[start..] };
            }
        }
    }
};

test {
    var p = Parser{ .input = " Hello {name}   " };
    while (try p.next()) |n| {
        switch (n) {
            .format => |f| std.log.err("format [{s}]", .{f}),
            .text => |f| std.log.err("[{s}]", .{f}),
        }
    }
}
