import Foundation

/// A nanosecond-capable civil time of day.
///
/// `PureTime` is not an elapsed duration and has no date or time zone. Its
/// finite domain runs from midnight through the exact, distinct `24:00:00`
/// endpoint. The endpoint is useful for database time-of-day semantics but is
/// never stored as a finite `DateTime` component; `DateTime` canonicalizes it
/// to the following date's midnight.
public struct PureTime: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    private static let nanosecondsPerSecond: Int64 = 1_000_000_000
    private static let nanosecondsPerMinute: Int64 = 60 * nanosecondsPerSecond
    private static let nanosecondsPerHour: Int64 = 60 * nanosecondsPerMinute
    private static let nanosecondsPerDay: Int64 = 24 * nanosecondsPerHour

    private let rawNanoseconds: Int64

    private init(validatedNanosecondsSinceMidnight: Int64) {
        rawNanoseconds = validatedNanosecondsSinceMidnight
    }

    /// Creates a civil time of day with nanosecond precision.
    ///
    /// Hours 0...23 use ordinary clock components. Hour 24 is accepted only
    /// as the exact `24:00:00` endpoint. Leap seconds, negative components,
    /// and values beyond one civil day are rejected.
    public init?(hour: Int, minute: Int, second: Int = 0, nanosecond: Int = 0) {
        guard minute >= 0, minute <= 59,
              second >= 0, second <= 59,
              nanosecond >= 0, nanosecond <= 999_999_999 else {
            return nil
        }

        if hour == 24 {
            guard minute == 0, second == 0, nanosecond == 0 else {
                return nil
            }
        } else {
            guard hour >= 0, hour <= 23 else {
                return nil
            }
        }

        let value = Int64(hour) * Self.nanosecondsPerHour
            + Int64(minute) * Self.nanosecondsPerMinute
            + Int64(second) * Self.nanosecondsPerSecond
            + Int64(nanosecond)
        self.init(validatedNanosecondsSinceMidnight: value)
    }

    /// Creates a civil time from nanoseconds since the start of its day.
    ///
    /// The accepted coordinate is exactly 0...86,400,000,000,000 inclusive;
    /// it is a time-of-day coordinate, not an arbitrary elapsed duration.
    public init?(nanosecondsSinceMidnight: Int64) {
        guard (0...Self.nanosecondsPerDay).contains(nanosecondsSinceMidnight) else {
            return nil
        }
        self.init(validatedNanosecondsSinceMidnight: nanosecondsSinceMidnight)
    }

    /// Parses the stable `HH:mm:ss[.fraction]` time-of-day grammar.
    ///
    /// Fractions contain one through nine decimal digits and are scaled to
    /// nanoseconds. Parsed values are rendered canonically by `description`.
    public init?(_ string: String) {
        let bytes = Array(string.utf8)
        guard bytes.count >= 8,
              let hour = Self.parseTwoDigits(bytes, at: 0),
              bytes[2] == 58,
              let minute = Self.parseTwoDigits(bytes, at: 3),
              bytes[5] == 58,
              let second = Self.parseTwoDigits(bytes, at: 6) else {
            return nil
        }

        var nanosecond = 0
        if bytes.count > 8 {
            guard bytes[8] == 46 else {
                return nil
            }
            let fractionStart = 9
            let fractionLength = bytes.count - fractionStart
            guard (1...9).contains(fractionLength),
                  bytes[fractionStart..<bytes.count].allSatisfy(Self.isDigit) else {
                return nil
            }

            var fraction: Int64 = 0
            for byte in bytes[fractionStart..<bytes.count] {
                fraction = fraction * 10 + Int64(byte - 48)
            }
            for _ in 0..<(9 - fractionLength) {
                fraction *= 10
            }
            nanosecond = Int(fraction)
        }

        guard let value = Self(hour: hour, minute: minute, second: second, nanosecond: nanosecond) else {
            return nil
        }
        if hour == 24, bytes.count > 8 {
            return nil
        }
        self = value
    }

    /// Midnight, represented by coordinate zero.
    public static let midnight = Self(validatedNanosecondsSinceMidnight: 0)

    /// The exact end-of-day endpoint `24:00:00`, distinct from `midnight`.
    public static let endOfDay = Self(validatedNanosecondsSinceMidnight: nanosecondsPerDay)

    /// The hour component, including 24 for `endOfDay`.
    public var hour: Int {
        Int(rawNanoseconds / Self.nanosecondsPerHour)
    }

    /// The minute component within the hour.
    public var minute: Int {
        Int((rawNanoseconds % Self.nanosecondsPerHour) / Self.nanosecondsPerMinute)
    }

    /// The second component within the minute. The value is always 0...59.
    public var second: Int {
        Int((rawNanoseconds % Self.nanosecondsPerMinute) / Self.nanosecondsPerSecond)
    }

    /// The fractional nanosecond component within the second.
    public var nanosecond: Int {
        Int(rawNanoseconds % Self.nanosecondsPerSecond)
    }

    /// The exact coordinate since midnight, including the `endOfDay` endpoint.
    public var nanosecondsSinceMidnight: Int64 {
        rawNanoseconds
    }

    /// The canonical `HH:mm:ss[.fraction]` spelling.
    public var description: String {
        let base = "\(Self.twoDigits(hour)):\(Self.twoDigits(minute)):\(Self.twoDigits(second))"
        guard nanosecond != 0 else {
            return base
        }

        let digits = String(nanosecond)
        var fraction = String(repeating: "0", count: 9 - digits.count) + digits
        while fraction.last == "0" {
            fraction.removeLast()
        }
        return "\(base).\(fraction)"
    }

    /// Encodes the canonical single time string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// Decodes the canonical single time string.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = Self(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid canonical PureTime string"
            )
        }
        self = value
    }

    /// Compares civil times by their exact nanosecond coordinate.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawNanoseconds < rhs.rawNanoseconds
    }

    private static func parseTwoDigits(_ bytes: [UInt8], at index: Int) -> Int? {
        guard index >= 0, index + 1 < bytes.count,
              isDigit(bytes[index]), isDigit(bytes[index + 1]) else {
            return nil
        }
        return Int(bytes[index] - 48) * 10 + Int(bytes[index + 1] - 48)
    }

    private static func isDigit(_ byte: UInt8) -> Bool {
        (48...57).contains(byte)
    }

    private static func twoDigits(_ value: Int) -> String {
        let digits = String(value)
        if digits.count >= 2 {
            return digits
        }
        return "0" + digits
    }
}
