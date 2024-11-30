const std = @import("std");

pub const SubProcess = struct {
    alloc: std.mem.Allocator,
    file: [:0]u8,
    args: std.ArrayList([:0]u8),
    env: std.ArrayList([:0]u8),
    pub fn init(
        alloc: std.mem.Allocator,
        file: []const u8,
        args: []const []const u8,
        env: []const []const u8,
    ) !SubProcess {
        var self = SubProcess{
            .alloc = alloc,
            .file = try alloc.dupeZ(file),
            .args = std.ArrayList([]u8).init(alloc),
            .env = std.ArrayList([]u8).init(alloc),
        };
        errdefer self.deinit();

        for (args) |a| {
            const d = try self.alloc.dupeZ(u8, a);
            errdefer self.alloc.free(a);
            try self.args.append(d);
        }
        for (env) |a| {
            const d = try self.alloc.dupeZ(u8, a);
            errdefer self.alloc.free(a);
            try self.env.append(d);
        }
        //

        return self;
    }
    pub fn deinit(self: SubProcess) void {
        self.file.deinit();
        for (self.args.items) |i| self.alloc.free(i);
        self.args.deinit();
        for (self.env.items) |i| self.alloc.free(i);
        self.env.deinit();
    }
    pub const ProcRun = struct {
        pub const childPids = struct {
            stdin: std.posix.fd_t,
            stdout: std.posix.fd_t,
            stderr: std.posix.fd_t,
        };
        pid: std.posix.fd_t,
    };
    pub fn run(self: SubProcess) !ProcRun {
        const child_pid = try std.posix.fork();
        switch (child_pid) {
            0 => {},
            else => {
                //
            },
        }
        //
    }
};
