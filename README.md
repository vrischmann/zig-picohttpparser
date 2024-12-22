# zig-picohttpparser

This is a small Zig wrapper to use [picohttpparser](https://github.com/h2o/picohttpparser)

This package leverages the Zig build system and is based on [zig-picohttpparser-sys](https://github.com/vrischmann/zig-picohttpparser-sys).

# Installation

Use `zig fetch`:

```
zig fetch --save git+https://github.com/vrischmann/zig-picohttpparser#master
```

You can then import `picohttpparser` in your `build.zig`:
```zig
const picohttpparser = b.dependency("picohttpparser", .{
    .target = target,
    .optimize = optimize,
});

your_exe.addImport("picohttpparser", picohttpparser.module("picohttpparser"));
```

# Usage

There is only one function exposed, `parseRequest`:
```
pub fn parseRequest(buffer: []const u8, previous_buffer_len: usize) ParseRequestError!?ParseRequestResult {
```

This function takes in a _buffer_ and a _previous buffer length_ and returns either a parsing error or a result.

The buffer is easy to understand, it's the string you want to parse as an HTTP request.
The previous buffer length is the length in the current buffer that you already tried to parse. This is needed to resume parsing incomplete buffers.

The returned result contains the raw request (of type `RawRequest`) and the number of bytes consumed from the buffer.

Here is an example usage:
```zig
const std = @import("std");
const picohttpparser = @import("picohttpparser");

pub fn main() !void {
    const data = "GET /lol/foo HTTP/1.0\r\nfoo: ab\r\nContent-Length: 200\r\n\r\n";

    if (try picohttpparser.parseRequest(data, 0)) |result| {
        std.log.info("request: {s}, consumed: {d}", .{ result.raw_request.getPath(), result.consumed });
    }
}
```

This assumes the data is complete, in the real world you probably can't assume this. You probably want to do something like this:
```zig
var buf = std.ArrayList(u8).init(allocator);
const result = while (true) {
    // Feed more data to buf somehow: read from a socket, copy from another buffer, etc

    if (try picohttpparser.parseRequest(buf.items, 0)) |result| {
        break result;
    }
};

// Use the result
```

Look into [example/main.zig](/example/main.zig) for a more complete example.
