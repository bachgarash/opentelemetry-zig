/// Generic interface for getting values from a carrier.
///
/// Implementations must provide methods to retrieve propagation data from
/// carriers like HTTP headers or environment variables.
pub fn TextMapGetter(comptime Carrier: type) type {
    return struct {
        /// Get a single value for a given key.
        /// Returns null if the key doesn't exist.
        /// Must be case-insensitive for HTTP carriers.
        getFn: *const fn (carrier: *const Carrier, key: []const u8) ?[]const u8,

        /// Get all keys available in the carrier.
        /// Returns a slice of key names.
        keysFn: *const fn (carrier: *const Carrier) []const []const u8,

        const Self = @This();

        pub fn get(self: Self, carrier: *const Carrier, key: []const u8) ?[]const u8 {
            return self.getFn(carrier, key);
        }

        pub fn keys(self: Self, carrier: *const Carrier) []const []const u8 {
            return self.keysFn(carrier);
        }
    };
}

/// Generic interface for setting values in a carrier.
///
/// Implementations must provide a method to inject propagation data into
/// carriers like HTTP headers or environment variables.
pub fn TextMapSetter(comptime Carrier: type) type {
    return struct {
        /// Set a key-value pair in the carrier.
        /// Should preserve casing for the key.
        setFn: *const fn (carrier: *Carrier, key: []const u8, value: []const u8) anyerror!void,

        const Self = @This();

        pub fn set(self: Self, carrier: *Carrier, key: []const u8, value: []const u8) !void {
            return self.setFn(carrier, key, value);
        }
    };
}
