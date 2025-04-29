const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;

const picohttpparser = @import("picohttpparser");

pub fn main() !void {
    {
        debug.print("\x1b[33mcomplete data\x1b[0m\n", .{});

        const data = "GET /lol/foo HTTP/1.0\r\nfoo: ab\r\nContent-Length: 200\r\n\r\n";

        debug.print("data: {s}\n", .{fmt.fmtSliceEscapeLower(data)});

        if (try picohttpparser.parseRequest(data, 0)) |result| {
            debug.print("request: {s}, consumed: {d}\n", .{ result.raw_request.getPath(), result.consumed });
        }
    }

    {
        debug.print("\x1b[33mincomplete data\x1b[0m\n", .{});

        var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

        var data = std.ArrayList(u8).init(gpa.allocator());
        var count: usize = 0;

        const result = while (true) {
            // You probably want to do proper error handling here.
            const tmp = try picohttpparser.parseRequest(data.items, 0);

            if (tmp) |result| {
                break result;
            } else {
                debug.print("invalid request data (len={d}): {s}\n", .{ data.items.len, fmt.fmtSliceEscapeLower(data.items) });
            }

            // This simulates reading incomplete data from a socket or something like that.
            if (count == 0) {
                try data.appendSlice("GET /lol/foo");
                count += 1;
            } else if (count == 1) {
                try data.appendSlice(" HTTP/1.0\r\nfoo: ab\r");
                count += 1;
            } else if (count == 2) {
                try data.appendSlice("\nContent-Length: 200\r\n\r\n");
                try data.appendSlice("fooobar");
                count += 1;
            }
        };

        debug.print("request: {s}, consumed: {d}, remaining in buffer: {d}\n", .{
            result.raw_request.getPath(),
            result.consumed,
            data.items.len - result.consumed,
        });
    }
}
