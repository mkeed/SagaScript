const std = @import("std");
const Dag = @import("Dag.zig");

pub const DagItem = struct {
    val: u32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var dag = Dag.Dag(.{ .T = DagItem }).init(alloc);
    defer dag.deinit();
    var list = std.ArrayList(Dag.NodeId).init(alloc);
    defer list.deinit();
    const id1 = try dag.addItem(.{ .val = 123 }, &.{});

    const id2 = try dag.addItem(.{ .val = 123 }, &.{});

    const new_vals = [_]u32{ 111, 222, 333, 444, 555, 666 };
    for (new_vals) |v| {
        const id = try dag.addItem(.{ .val = v }, &.{ id1, id2 });
        try list.append(id);
    }
    const stdout = std.io.getStdOut();
    var bufw = std.io.bufferedWriter(stdout.writer());
    defer _ = bufw.flush() catch {};
    try dag.print(bufw.writer());
}
