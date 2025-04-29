const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;

const picohttpparser = @import("picohttpparser");

pub fn main() !void {
    {
        debug.print("\x1b[33mcomplete data\x1b[0m\n", .{});

        const data =
            "HTTP/1.1 200 OK\r\n" ++
            "Content-Type: text/plain\r\n" ++
            "Content-Length: 13\r\n" ++
            "\r\n" ++
            "Hello, World!";

        debug.print("data: {s}\n", .{fmt.fmtSliceEscapeLower(data)});

        if (try picohttpparser.parseResponse(data, 0)) |result| {
            debug.print("response: {d} {s}, consumed: {d}\n", .{
                result.raw_response.getStatus(),
                result.raw_response.getMessage(),
                result.consumed,
            });
        }
    }

    {
        debug.print("\x1b[33mincomplete data\x1b[0m\n", .{});

        var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;

        var data = std.ArrayList(u8).init(gpa.allocator());
        var count: usize = 0;

        const result = while (true) {
            const tmp = try picohttpparser.parseResponse(data.items, 0);

            if (tmp) |result| {
                break result;
            } else {
                debug.print("invalid response data (len={d}): {s}\n", .{ data.items.len, fmt.fmtSliceEscapeLower(data.items) });
            }

            // Simulating reading incomplete response data in chunks.
            if (count == 0) {
                try data.appendSlice("HTTP/1.1 200 ");
                count += 1;
            } else if (count == 1) {
                try data.appendSlice("OK\r\nContent-Type: text/pl");
                count += 1;
            } else if (count == 2) {
                try data.appendSlice("ain\r\nContent-Length: 13\r\n\r\nHello, World!");
                count += 1;
            }
        };

        debug.print("response: {d} {s}, consumed: {d}, remaining in buffer: {d}\n", .{
            result.raw_response.getStatus(),
            result.raw_response.getMessage(),
            result.consumed,
            data.items.len - result.consumed,
        });
    }
}
