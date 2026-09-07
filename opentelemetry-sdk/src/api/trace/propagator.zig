//! OpenTelemetry W3C Trace Context Propagator.
//!
//! This module implements the W3C Trace Context specification for propagating
//! SpanContext across process boundaries via the `traceparent` and `tracestate`
//! HTTP headers.
//!
//! `traceparent` format: `version-trace_id-parent_id-trace_flags`
//! - Dash-delimited, hex-encoded fields
//! - `version`: 2 hex chars (currently only `00` is fully specified)
//! - `trace_id`: 32 hex chars (16 bytes), must not be all zeros
//! - `parent_id`: 16 hex chars (8 bytes), must not be all zeros
//! - `trace_flags`: 2 hex chars (1 byte), e.g. bit 0 is the sampled flag
//! - Fixed total length of 55 characters for version `00`
//!
//! `tracestate` format: comma-separated `key=value` vendor entries
//! - Up to 32 list-members
//! - A modified or newly-added key moves to the front (leftmost) of the list
//!
//! Example usage:
//! ```zig
//! const propagator = @import("opentelemetry-sdk").api.trace.propagator;
//!
//! var headers = std.StringHashMap([]const u8).init(allocator);
//! try propagator.inject(span_context, &headers, HttpSetter);
//!
//! const extracted = try propagator.extract(&headers, HttpGetter);
//! ```
//!
//! From W3C Trace Context specification: https://www.w3.org/TR/trace-context/
//!

const std = @import("std");
const SpanContext = @import("span.zig").SpanContext;
const TraceID = @import("../trace.zig").TraceID;
const SpanID = @import("../trace.zig").SpanID;
const propagator = @import("../propagation.zig");

const w3c_header_length = 55; // Length of the traceparent header for version 00
const traceparent_header = "traceparent";
const tracestate_header = "tracestate";
const version = "00"; // Current version of the traceparent header

pub fn inject(allocator: std.mem.Allocator, span_context: SpanContext, carrier: anytype, setter: propagator.TextMapSetter(@TypeOf(carrier.*))) !void {
    const traceId = span_context.getTraceId();
    const spanId = span_context.getSpanId();
    const traceFlags = span_context.getTraceFlags();

    var traceBuf: [32]u8 = undefined;
    const traceIDHex = TraceID.toHex(traceId, &traceBuf);

    var spanBuf: [16]u8 = undefined;
    const spanIDHex = SpanID.toHex(spanId, &spanBuf);

    const traceparentValue = try std.fmt.allocPrint(allocator, "{s}-{s}-{s}-{x:0>2}", .{ version, traceIDHex, spanIDHex, traceFlags.value });

    try setter.set(carrier, traceparent_header, traceparentValue);
}
