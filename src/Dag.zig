const std = @import("std");

pub const NodeId = struct {
    id: u32,
};

fn NodeGen(comptime T: type) type {
    return struct {
        const Self = @This();
        val: T,
        id: NodeId,
        prereq: std.ArrayList(NodeId),

        pub fn init(alloc: std.mem.Allocator, id: NodeId, val: T) Self {
            return Self{
                .val = val,
                .id = id,
                .prereq = std.ArrayList(NodeId).init(alloc),
            };
        }

        pub fn deinit(self: Self) void {
            self.prereq.deinit();
        }
    };
}

pub const DagOpts = struct {
    T: type,
};

pub fn Dag(opts: DagOpts) type {
    return struct {
        const Self = @This();
        const Node = NodeGen(opts.T);
        alloc: std.mem.Allocator,
        items: std.ArrayList(Node),
        curId: u32,

        pub fn init(alloc: std.mem.Allocator) Self {
            return Self{
                .alloc = alloc,
                .items = std.ArrayList(Node).init(alloc),
                .curId = 0,
            };
        }
        pub fn deinit(self: Self) void {
            for (self.items.items) |i| {
                i.deinit();
            }
            self.items.deinit();
        }
        pub fn addItem(self: *Self, val: opts.T, preReq: []const NodeId) !NodeId {
            const id = NodeId{ .id = self.curId };
            self.curId += 1;

            var n = Node.init(self.alloc, id, val);
            errdefer n.deinit();
            for (preReq) |p| {
                if (self.getNode(p)) |_| {} else {
                    return error.InvalidPreReq;
                }
            }
            try n.prereq.appendSlice(preReq);

            try self.items.append(n);
            return id;
        }
        pub fn getNode(self: Self, nodeId: NodeId) ?Node {
            for (self.items.items) |i| {
                if (i.id.id == nodeId.id) return i;
            }
            return null;
        }
        pub fn print(self: Self, writer: anytype) !void {
            for (self.items.items) |i| {
                try std.fmt.format(writer, "[{} => [", .{i.id.id});
                for (i.prereq.items) |p| {
                    try std.fmt.format(writer, "{},", .{p.id});
                }
                try std.fmt.format(writer, "]\n", .{});
            }
        }
    };
}
