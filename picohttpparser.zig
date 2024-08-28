const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;

const c = @cImport({
    @cInclude("picohttpparser.h");
});

pub const RawHeader = struct {
    name: []const u8,
    value: []const u8,
};

/// Request type contains fields populated by picohttpparser and provides helpers methods for easier use with Zig.
pub const RawRequest = struct {
    pub const max_headers = 100;

    method: [*c]u8 = undefined,
    method_len: usize = undefined,
    path: [*c]u8 = undefined,
    path_len: usize = undefined,
    minor_version: c_int = 0,
    headers: [max_headers]c.phr_header = undefined,
    num_headers: usize = max_headers,

    pub fn getMethod(self: RawRequest) []const u8 {
        return self.method[0..self.method_len];
    }

    pub fn getPath(self: RawRequest) []const u8 {
        return self.path[0..self.path_len];
    }

    pub fn getMinorVersion(self: RawRequest) usize {
        return @as(usize, @intCast(self.minor_version));
    }

    pub const CopyHeadersAllocError = error{} || CopyHeadersError || mem.Allocator.Error;

    pub fn copyHeadersAlloc(self: RawRequest, allocator: mem.Allocator) CopyHeadersAllocError![]const RawHeader {
        const headers = try allocator.alloc(RawHeader, self.num_headers);

        _ = try self.copyHeaders(headers);

        return headers;
    }

    pub const CopyHeadersError = error{DestTooSmall};

    pub fn copyHeaders(self: RawRequest, dest: []RawHeader) CopyHeadersError!usize {
        if (dest.len < self.num_headers) {
            return error.DestTooSmall;
        }

        var i: usize = 0;
        while (i < self.num_headers) : (i += 1) {
            const hdr = self.headers[i];

            const name = hdr.name[0..hdr.name_len];
            const value = hdr.value[0..hdr.value_len];

            dest[i].name = name;
            dest[i].value = value;
        }

        return self.num_headers;
    }

    pub fn getContentLength(self: RawRequest) !?usize {
        var i: usize = 0;
        while (i < self.num_headers) : (i += 1) {
            const hdr = self.headers[i];

            const name = hdr.name[0..hdr.name_len];
            const value = hdr.value[0..hdr.value_len];

            if (!std.ascii.eqlIgnoreCase(name, "Content-Length")) {
                continue;
            }
            return try fmt.parseInt(usize, value, 10);
        }
        return null;
    }
};

pub const ParseRequestResult = struct {
    raw_request: RawRequest,
    consumed: usize,
};

pub const ParseRequestError = error{
    InvalidRequestData,
};

pub fn parseRequest(previous_buffer_len: usize, buffer: []const u8) ParseRequestError!?ParseRequestResult {
    var req = RawRequest{};

    const res = c.phr_parse_request(
        buffer.ptr,
        buffer.len,
        &req.method,
        &req.method_len,
        &req.path,
        &req.path_len,
        &req.minor_version,
        &req.headers,
        &req.num_headers,
        previous_buffer_len,
    );
    if (res == -1) return error.InvalidRequestData;
    if (res == -2) return null;

    return ParseRequestResult{
        .raw_request = req,
        .consumed = @as(usize, @intCast(res)),
    };
}

test "parseRequest" {
    const TestCase = struct {
        input: []const u8,
        method: []const u8,
        path: []const u8,
        minor_version: usize,
        content_length: ?usize,
    };

    const testCases = &[_]TestCase{
        .{
            .input = "GET /hoge HTTP/1.1\r\nHost: example.com\r\nUser-Agent: foobar/1.0\r\n\r\n",
            .method = "GET",
            .path = "/hoge",
            .minor_version = 1,
            .content_length = null,
        },
        .{
            .input = "GET / HTTP/1.0\r\nfoo: ab\r\nContent-Length: 200\r\n\r\n",
            .method = "GET",
            .path = "/",
            .minor_version = 0,
            .content_length = 200,
        },
    };

    inline for (testCases) |tc| {
        const result = try parseRequest(0, tc.input);
        try testing.expect(result != null);
        try testing.expectEqual(tc.input.len, result.?.consumed);

        const req = result.?.raw_request;

        try testing.expectEqualStrings(tc.method, req.getMethod());
        try testing.expectEqualStrings(tc.path, req.getPath());
        try testing.expectEqual(tc.minor_version, req.getMinorVersion());
        try testing.expectEqual(tc.content_length, req.getContentLength());
    }
}

test "raw request" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const raw_request_data = "GET / HTTP/1.0\r\nfoo: ab\r\nContent-Length: 200\r\n\r\n";

    const result = try parseRequest(0, raw_request_data);
    try testing.expect(result != null);
    try testing.expectEqual(raw_request_data.len, result.?.consumed);

    const req = result.?.raw_request;

    var headers_storage: [RawRequest.max_headers]RawHeader = undefined;
    const num_headers = try req.copyHeaders(&headers_storage);
    try testing.expectEqual(@as(usize, 2), num_headers);

    const headers2 = try req.copyHeadersAlloc(arena.allocator());
    try testing.expectEqualSlices(RawHeader, headers_storage[0..num_headers], headers2);
}

test {
    testing.refAllDecls(@This());
}
