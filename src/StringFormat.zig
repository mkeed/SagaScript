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

pub fn format(out: *std.ArrayList(u8), fmt: []const u8, vars: *const VStore) !void {
    var p = Parser{ .input = fmt };
    while (try p.next()) |n| {
        switch (n) {
            .format => |f| {
                if (vars.get(f)) |val| {
                    try out.appendSlice(val);
                } else {
                    return error.MissingVariable;
                }
            },
            .text => |f| {
                try out.appendSlice(f);
            },
        }
    }
}

test {
    const alloc = std.testing.allocator;
    var vars = VStore.init(alloc);
    defer vars.deinit();
    try vars.set("name", "Test Name");
    var out = std.ArrayList(u8).init(alloc);
    defer out.deinit();
    try format(&out, "Hello {name}", &vars);
    try std.testing.expectEqualSlices(u8, "Hello Test Name", out.items);
}
