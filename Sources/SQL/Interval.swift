import Foundation

/// A calendar-aware interval with independent month, day, and microsecond parts.
///
/// `Interval` is not `Foundation.TimeInterval`: months and days are calendar
/// quantities and remain structurally independent from fixed microseconds.
/// Mixed signs are valid, and finite values are not normalized. The explicit
/// infinity values model database special states. Conversion to Swift
/// `Duration` is available only for finite intervals whose month and day parts
/// are both zero.
public struct Interval: Sendable, Hashable, Codable {
    private enum Storage: Sendable, Hashable {
        case finite(months: Int64, days: Int64, microseconds: Int64)
        case positiveInfinity
        case negativeInfinity
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Creates a finite interval while preserving each basis component exactly.
    public init(months: Int64 = 0, days: Int64 = 0, microseconds: Int64 = 0) {
        storage = .finite(months: months, days: days, microseconds: microseconds)
    }

    /// An explicit positive-infinity database/arithmetic special state.
    public static let positiveInfinity = Self(storage: .positiveInfinity)

    /// An explicit negative-infinity database/arithmetic special state.
    public static let negativeInfinity = Self(storage: .negativeInfinity)

    /// The finite all-zero interval.
    public static let zero = Self(storage: .finite(months: 0, days: 0, microseconds: 0))

    /// Whether this value contains finite month, day, and microsecond parts.
    public var isFinite: Bool {
        if case .finite = storage {
            return true
        }
        return false
    }

    /// Whether this is the finite interval whose three basis components are zero.
    public var isZero: Bool {
        guard case let .finite(months, days, microseconds) = storage else {
            return false
        }
        return months == 0 && days == 0 && microseconds == 0
    }

    /// The independent month component, or `nil` for an infinity.
    public var months: Int64? {
        guard case let .finite(months, _, _) = storage else {
            return nil
        }
        return months
    }

    /// The independent day component, or `nil` for an infinity.
    public var days: Int64? {
        guard case let .finite(_, days, _) = storage else {
            return nil
        }
        return days
    }

    /// The independent fixed microsecond component, or `nil` for an infinity.
    public var microseconds: Int64? {
        guard case let .finite(_, _, microseconds) = storage else {
            return nil
        }
        return microseconds
    }

    /// Creates a month component from a year count when multiplication fits.
    public static func years(_ value: Int64) -> Interval? {
        guard let months = Self.multiplied(value, by: 12) else {
            return nil
        }
        return Self(months: months)
    }

    /// Creates a structural month component without converting it to days.
    public static func months(_ value: Int64) -> Interval {
        Self(months: value)
    }

    /// Creates a day component from a week count when multiplication fits.
    public static func weeks(_ value: Int64) -> Interval? {
        guard let days = Self.multiplied(value, by: 7) else {
            return nil
        }
        return Self(days: days)
    }

    /// Creates a structural day component without converting it to months.
    public static func days(_ value: Int64) -> Interval {
        Self(days: value)
    }

    /// Creates a fixed microsecond component from an hour count when multiplication fits.
    public static func hours(_ value: Int64) -> Interval? {
        guard let microseconds = Self.multiplied(value, by: 3_600_000_000) else {
            return nil
        }
        return Self(microseconds: microseconds)
    }

    /// Creates a fixed microsecond component from a minute count when multiplication fits.
    public static func minutes(_ value: Int64) -> Interval? {
        guard let microseconds = Self.multiplied(value, by: 60_000_000) else {
            return nil
        }
        return Self(microseconds: microseconds)
    }

    /// Creates a fixed microsecond component from a second count when multiplication fits.
    public static func seconds(_ value: Int64) -> Interval? {
        guard let microseconds = Self.multiplied(value, by: 1_000_000) else {
            return nil
        }
        return Self(microseconds: microseconds)
    }

    /// Creates a fixed microsecond component from a millisecond count when multiplication fits.
    public static func milliseconds(_ value: Int64) -> Interval? {
        guard let microseconds = Self.multiplied(value, by: 1_000) else {
            return nil
        }
        return Self(microseconds: microseconds)
    }

    /// Creates a fixed microsecond component without introducing nanosecond precision.
    public static func microseconds(_ value: Int64) -> Interval {
        Self(microseconds: value)
    }

    /// Returns the checked additive inverse, or `nil` if a finite component is `Int64.min`.
    public func negated() -> Interval? {
        switch storage {
        case .positiveInfinity:
            return .negativeInfinity
        case .negativeInfinity:
            return .positiveInfinity
        case let .finite(months, days, microseconds):
            guard let months = Self.negated(months),
                  let days = Self.negated(days),
                  let microseconds = Self.negated(microseconds) else {
                return nil
            }
            return Self(months: months, days: days, microseconds: microseconds)
        }
    }

    /// Adds two intervals with checked finite arithmetic and explicit infinity rules.
    public func adding(_ other: Interval) -> Interval? {
        switch (storage, other.storage) {
        case (.positiveInfinity, .positiveInfinity),
             (.positiveInfinity, .finite),
             (.finite, .positiveInfinity):
            return .positiveInfinity
        case (.negativeInfinity, .negativeInfinity),
             (.negativeInfinity, .finite),
             (.finite, .negativeInfinity):
            return .negativeInfinity
        case (.positiveInfinity, .negativeInfinity),
             (.negativeInfinity, .positiveInfinity):
            return nil
        case let (.finite(lhsMonths, lhsDays, lhsMicroseconds), .finite(rhsMonths, rhsDays, rhsMicroseconds)):
            guard let months = Self.adding(lhsMonths, rhsMonths),
                  let days = Self.adding(lhsDays, rhsDays),
                  let microseconds = Self.adding(lhsMicroseconds, rhsMicroseconds) else {
                return nil
            }
            return Self(months: months, days: days, microseconds: microseconds)
        }
    }

    /// Subtracts two intervals with checked finite arithmetic and explicit infinity rules.
    public func subtracting(_ other: Interval) -> Interval? {
        switch (storage, other.storage) {
        case (.positiveInfinity, .positiveInfinity),
             (.negativeInfinity, .negativeInfinity):
            return nil
        case (.positiveInfinity, .negativeInfinity),
             (.positiveInfinity, .finite):
            return .positiveInfinity
        case (.negativeInfinity, .positiveInfinity),
             (.negativeInfinity, .finite):
            return .negativeInfinity
        case (.finite, .positiveInfinity):
            return .negativeInfinity
        case (.finite, .negativeInfinity):
            return .positiveInfinity
        case let (.finite(lhsMonths, lhsDays, lhsMicroseconds), .finite(rhsMonths, rhsDays, rhsMicroseconds)):
            guard let months = Self.subtracting(lhsMonths, rhsMonths),
                  let days = Self.subtracting(lhsDays, rhsDays),
                  let microseconds = Self.subtracting(lhsMicroseconds, rhsMicroseconds) else {
                return nil
            }
            return Self(months: months, days: days, microseconds: microseconds)
        }
    }

    /// Converts a finite fixed-only interval to an exact Swift `Duration`.
    ///
    /// The conversion returns `nil` for infinities and for any interval with a
    /// nonzero month or day component. Microseconds are represented exactly;
    /// no floating-point `TimeInterval` intermediary is used.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public var duration: Duration? {
        guard case let .finite(months, days, microseconds) = storage,
              months == 0,
              days == 0 else {
            return nil
        }
        return Duration.microseconds(microseconds)
    }

    /// Encodes the tagged finite or infinity representation.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch storage {
        case let .finite(months, days, microseconds):
            try container.encode("finite", forKey: .kind)
            try container.encode(months, forKey: .months)
            try container.encode(days, forKey: .days)
            try container.encode(microseconds, forKey: .microseconds)
        case .positiveInfinity:
            try container.encode("positiveInfinity", forKey: .kind)
        case .negativeInfinity:
            try container.encode("negativeInfinity", forKey: .kind)
        }
    }

    /// Decodes the tagged finite or infinity representation.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)

        switch kind {
        case "finite":
            let months = try container.decode(Int64.self, forKey: .months)
            let days = try container.decode(Int64.self, forKey: .days)
            let microseconds = try container.decode(Int64.self, forKey: .microseconds)
            storage = .finite(months: months, days: days, microseconds: microseconds)
        case "positiveInfinity":
            guard !container.contains(.months),
                  !container.contains(.days),
                  !container.contains(.microseconds) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "Infinity Interval cannot contain finite basis fields"
                )
            }
            storage = .positiveInfinity
        case "negativeInfinity":
            guard !container.contains(.months),
                  !container.contains(.days),
                  !container.contains(.microseconds) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "Infinity Interval cannot contain finite basis fields"
                )
            }
            storage = .negativeInfinity
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unknown Interval kind"
            )
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case months
        case days
        case microseconds
    }

    private static func multiplied(_ lhs: Int64, by rhs: Int64) -> Int64? {
        let result = lhs.multipliedReportingOverflow(by: rhs)
        return result.overflow ? nil : result.partialValue
    }

    private static func negated(_ value: Int64) -> Int64? {
        let result = value.multipliedReportingOverflow(by: -1)
        return result.overflow ? nil : result.partialValue
    }

    private static func adding(_ lhs: Int64, _ rhs: Int64) -> Int64? {
        let result = lhs.addingReportingOverflow(rhs)
        return result.overflow ? nil : result.partialValue
    }

    private static func subtracting(_ lhs: Int64, _ rhs: Int64) -> Int64? {
        let result = lhs.subtractingReportingOverflow(rhs)
        return result.overflow ? nil : result.partialValue
    }
}
