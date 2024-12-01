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
        var fileBuf = std.ArrayList(u8).init(alloc);
        defer fileBuf.deinit();
        var self = SubProcess{
            .alloc = alloc,
            .file = try alloc.dupeZ(file),
            .args = std.ArrayList([]u8).init(alloc),
            .env = std.ArrayList([]u8).init(alloc),
        };
        errdefer self.deinit();
        {
            const d = try self.alloc.dupeZ(u8, file);
            errdefer self.alloc.free(a);
            try self.args.append(d);
        }
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
        pub const PipeFds = struct {
            stdin: std.posix.fd_t,
            stdout: std.posix.fd_t,
            stderr: std.posix.fd_t,
        };
        pub const SubPipes = struct {
            const ReadEnd = 0;
            const WriteEnd = 1;
            stdin: [2]std.posix.fd_t,
            stdout: [2]std.posix.fd_t,
            stderr: [2]std.posix.fd_t,
            pub fn init() !SubPipes {
                const stderr = try std.posix.pipe2(.{ .CLOEXEC = false });
                errdefer std.posix.close(stderr[0]);
                errdefer std.posix.close(stderr[1]);
                const stdin = try std.posix.pipe2(.{ .CLOEXEC = false });
                errdefer std.posix.close(stdin[0]);
                errdefer std.posix.close(stdin[1]);
                const stdout = try std.posix.pipe2(.{ .CLOEXEC = false });
                errdefer std.posix.close(stdin[0]);
                errdefer std.posix.close(stdin[1]);
                return .{
                    .stdin = stdin,
                    .stdout = stdout,
                    .stderr = stderr,
                };
            }
            pub fn handleChild(self: SubPipes) !void {
                std.posix.close(std.posix.STDIN_FILENO);
                std.posix.dup2(self.stdin[WriteEnd], std.posix.STDIN_FILENO);
                std.posix.close(std.posix.STDERR_FILENO);
                std.posix.dup2(self.stdin[ReadEnd], std.posix.STDERR_FILENO);
                std.posix.close(std.posix.STDOUT_FILENO);
                std.posix.dup2(self.stdin[WriteEnd], std.posix.STDOUT_FILENO);

                //
            }
            pub fn getParent(self: SubPipes) !PipeFds {
                std.posix.close(self.stdin[ReadEnd]);
                std.posix.close(self.stdout[WriteEnd]);
                std.posix.close(self.stderr[WriteEnd]);
                return .{
                    .stdin = self.stdin[WriteEnd],
                    .stdout = self.stdin[ReadEnd],
                    .stderr = self.stderr[ReadEnd],
                };
            }
        };
        fds: PipeFds,
        pid: std.posix.pid_t,
    };
    pub fn run(self: SubProcess) !ProcRun {
        const pipes = try SubPipes.init();

        const child_pid = try std.posix.fork();
        switch (child_pid) {
            0 => {
                try pipes.handleChild();
            },
            else => {
                const fds = try pipes.getParent();
                return .{
                    .fds = fds,
                    .pid = child_pid,
                };
                //
            },
        }
        //
    }
};
