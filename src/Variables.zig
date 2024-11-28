const std = @import("std");

pub const VariableStore = struct {
    alloc: std.mem.Allocator,
    map: std.StringArrayHashMap(std.ArrayList(u8)),

    pub fn init(alloc: std.mem.Allocator) VariableStore {
        return .{
            .alloc = alloc,
            .map = std.StringArrayHashMap(std.ArrayList(u8)).init(alloc),
        };
    }
    pub fn deinit(self: *VariableStore) void {
        var iter = self.map.iterator();
        while (iter.next()) |n| {
            self.alloc.free(n.key_ptr.*);
            n.value_ptr.deinit();
        }
        self.map.deinit();
    }
    pub fn set(self: *VariableStore, key: []const u8, val: []const u8) !void {
        if (self.map.getEntry(key)) |entry| {
            entry.value_ptr.clearRetainingCapacity();
            try entry.value_ptr.appendSlice(val);
        } else {
            var val_in = std.ArrayList(u8).init(self.alloc);
            errdefer val_in.deinit();
            try val_in.appendSlice(val);
            const key_in = try self.alloc.dupe(u8, key);
            errdefer self.alloc.free(key_in);
            try self.map.put(key_in, val_in);
        }
    }
    pub fn get(self: VariableStore, key: []const u8) ?[]const u8 {
        if (self.map.getEntry(key)) |entry| {
            return entry.value_ptr.items;
        }
        return null;
    }
};
