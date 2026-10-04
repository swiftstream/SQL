import Foundation

/// A proleptic-Gregorian civil date with astronomical `Int64` year numbering.
///
/// `PureDate` identifies a year, month, and day only. It is not
/// `Foundation.Date`, has no time or time zone, and therefore does not identify
/// an instant. Year `0` is 1 BC and year `-1` is 2 BC. The explicit
/// `positiveInfinity` and `negativeInfinity` values model database temporal
/// special values and are not convertible to `Foundation.Date`.
public struct PureDate: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    private enum Storage: Sendable, Hashable {
        case finite(year: Int64, month: Int, day: Int)
        case positiveInfinity
        case negativeInfinity
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Creates a finite proleptic-Gregorian civil date when the components are valid.
    public init?(year: Int64, month: Int, day: Int) {
        guard Self.isValid(year: year, month: month, day: day) else {
            return nil
        }
        storage = .finite(year: year, month: month, day: day)
    }

    /// Parses the canonical date grammar used by `description` and `Codable`.
    ///
    /// Finite values use astronomical years such as `0000-01-01`,
    /// `-0001-01-01`, and `+10000-01-01`. The only special spellings are
    /// `infinity` and `-infinity`.
    public init?(_ string: String) {
        switch string {
        case "infinity":
            self = .positiveInfinity
            return
        case "-infinity":
            self = .negativeInfinity
            return
        default:
            break
        }

        let bytes = Array(string.utf8)
        guard let components = Self.parseFinite(bytes) else {
            return nil
        }
        self.init(year: components.year, month: components.month, day: components.day)
    }

    /// A date value greater than every finite date.
    public static let positiveInfinity = Self(storage: .positiveInfinity)

    /// A date value less than every finite date.
    public static let negativeInfinity = Self(storage: .negativeInfinity)

    /// Whether this value contains finite year, month, and day components.
    public var isFinite: Bool {
        if case .finite = storage {
            return true
        }
        return false
    }

    /// The astronomical year, or `nil` for an infinity.
    public var year: Int64? {
        guard case let .finite(year, _, _) = storage else {
            return nil
        }
        return year
    }

    /// The month in the range 1...12, or `nil` for an infinity.
    public var month: Int? {
        guard case let .finite(_, month, _) = storage else {
            return nil
        }
        return month
    }

    /// The valid civil day of the month, or `nil` for an infinity.
    public var day: Int? {
        guard case let .finite(_, _, day) = storage else {
            return nil
        }
        return day
    }

    /// The canonical date spelling used by `Codable`.
    public var description: String {
        switch storage {
        case .positiveInfinity:
            return "infinity"
        case .negativeInfinity:
            return "-infinity"
        case let .finite(year, month, day):
            return "\(Self.formatYear(year))-\(Self.twoDigits(month))-\(Self.twoDigits(day))"
        }
    }

    /// Creates a `Foundation.Date` at the requested civil date's midnight.
    ///
    /// The supplied calendar must be Gregorian and the supplied time zone is
    /// applied explicitly. The conversion returns `nil` for an infinity, a
    /// calendar/time-zone combination that cannot represent the date, or a
    /// Foundation range/normalization mismatch.
    public func date(calendar: Calendar, timeZone: TimeZone) -> Foundation.Date? {
        guard case let .finite(year, month, day) = storage,
              calendar.identifier == .gregorian,
              let foundationYear = Self.foundationYear(for: year) else {
            return nil
        }

        var calendar = calendar
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.timeZone = timeZone
        components.era = foundationYear.era
        components.year = foundationYear.year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.nanosecond = 0

        guard let date = calendar.date(from: components) else {
            return nil
        }

        let roundTrip = calendar.dateComponents(
            [.era, .year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: date
        )
        guard roundTrip.era == components.era,
              roundTrip.year == components.year,
              roundTrip.month == components.month,
              roundTrip.day == components.day,
              roundTrip.hour == components.hour,
              roundTrip.minute == components.minute,
              roundTrip.second == components.second,
              roundTrip.nanosecond == components.nanosecond else {
            return nil
        }
        return date
    }

    /// Creates a civil date from a `Foundation.Date` in an explicit Gregorian
    /// calendar and time zone.
    ///
    /// The date's local year/month/day components are copied into the
    /// proleptic-Gregorian astronomical year model. Non-Gregorian calendars and
    /// values whose components cannot be represented by `PureDate` return `nil`.
    public init?(date: Foundation.Date, calendar: Calendar, timeZone: TimeZone) {
        guard calendar.identifier == .gregorian else {
            return nil
        }

        var calendar = calendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)

        guard let era = components.era,
              let foundationYear = components.year,
              let month = components.month,
              let day = components.day,
              let astronomicalYear = Self.astronomicalYear(era: era, foundationYear: foundationYear) else {
            return nil
        }

        self.init(year: astronomicalYear, month: month, day: day)
    }

    /// Encodes the canonical single date string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// Decodes the canonical single date string.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = Self(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid canonical PureDate string"
            )
        }
        self = value
    }

    /// Compares infinities and finite civil dates chronologically.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        let lhsRank = lhs.orderingRank
        let rhsRank = rhs.orderingRank
        guard lhsRank == rhsRank else {
            return lhsRank < rhsRank
        }

        guard case let .finite(lhsYear, lhsMonth, lhsDay) = lhs.storage,
              case let .finite(rhsYear, rhsMonth, rhsDay) = rhs.storage else {
            return false
        }
        if lhsYear != rhsYear {
            return lhsYear < rhsYear
        }
        if lhsMonth != rhsMonth {
            return lhsMonth < rhsMonth
        }
        return lhsDay < rhsDay
    }

    /// Returns the next finite Gregorian civil date, or `nil` at the shared
    /// `Int64` year boundary or for an infinity.
    internal func addingOneDay() -> PureDate? {
        guard case let .finite(year, month, day) = storage else {
            return nil
        }

        let monthLength = Self.daysInMonth(year: year, month: month)
        if day < monthLength {
            return PureDate(year: year, month: month, day: day + 1)
        }
        if month < 12 {
            return PureDate(year: year, month: month + 1, day: 1)
        }
        guard year != Int64.max else {
            return nil
        }
        return PureDate(year: year + 1, month: 1, day: 1)
    }

    private var orderingRank: Int {
        switch storage {
        case .negativeInfinity:
            return 0
        case .finite:
            return 1
        case .positiveInfinity:
            return 2
        }
    }

    private static func isValid(year: Int64, month: Int, day: Int) -> Bool {
        guard (1...12).contains(month) else {
            return false
        }
        return (1...daysInMonth(year: year, month: month)).contains(day)
    }

    private static func isLeapYear(_ year: Int64) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    private static func daysInMonth(year: Int64, month: Int) -> Int {
        switch month {
        case 2:
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }

    private static func parseFinite(_ bytes: [UInt8]) -> (year: Int64, month: Int, day: Int)? {
        guard !bytes.isEmpty else {
            return nil
        }

        let sign = bytes[0]
        let yearStart: Int
        let yearEnd: Int
        let isNegative: Bool
        let hasExplicitPositiveSign: Bool

        switch sign {
        case 45:
            guard bytes.count > 1 else {
                return nil
            }
            yearStart = 1
            isNegative = true
            hasExplicitPositiveSign = false
        case 43:
            guard bytes.count > 1 else {
                return nil
            }
            yearStart = 1
            isNegative = false
            hasExplicitPositiveSign = true
        default:
            yearStart = 0
            isNegative = false
            hasExplicitPositiveSign = false
        }

        if hasExplicitPositiveSign || isNegative {
            guard let separator = bytes[yearStart...].firstIndex(of: 45) else {
                return nil
            }
            yearEnd = separator
            let digitCount = yearEnd - yearStart
            guard digitCount >= 4 else {
                return nil
            }
            if digitCount > 4, bytes[yearStart] == 48 {
                return nil
            }
        } else {
            guard bytes.count >= 5, bytes[4] == 45 else {
                return nil
            }
            yearEnd = 4
            guard bytes[0..<yearEnd].allSatisfy(Self.isDigit) else {
                return nil
            }
        }

        guard yearEnd + 6 == bytes.count,
              bytes[yearEnd] == 45,
              bytes[yearEnd + 3] == 45,
              let month = Self.parseTwoDigits(bytes, at: yearEnd + 1),
              let day = Self.parseTwoDigits(bytes, at: yearEnd + 4) else {
            return nil
        }

        guard let magnitude = Self.parseUInt64(bytes, from: yearStart, to: yearEnd) else {
            return nil
        }

        let year: Int64
        if isNegative {
            guard magnitude > 0, magnitude <= (UInt64(Int64.max) + 1) else {
                return nil
            }
            if magnitude == UInt64(Int64.max) + 1 {
                year = Int64.min
            } else {
                year = -Int64(magnitude)
            }
        } else if hasExplicitPositiveSign {
            guard magnitude > 9999, magnitude <= UInt64(Int64.max) else {
                return nil
            }
            year = Int64(magnitude)
        } else {
            guard magnitude <= 9999 else {
                return nil
            }
            year = Int64(magnitude)
        }

        guard Self.isValid(year: year, month: month, day: day) else {
            return nil
        }
        return (year, month, day)
    }

    private static func parseUInt64(_ bytes: [UInt8], from start: Int, to end: Int) -> UInt64? {
        guard start < end else {
            return nil
        }

        var result: UInt64 = 0
        for byte in bytes[start..<end] {
            guard Self.isDigit(byte) else {
                return nil
            }
            let digit = UInt64(byte - 48)
            let multiplication = result.multipliedReportingOverflow(by: 10)
            let addition = multiplication.partialValue.addingReportingOverflow(digit)
            guard !multiplication.overflow, !addition.overflow else {
                return nil
            }
            result = addition.partialValue
        }
        return result
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

    private static func formatYear(_ year: Int64) -> String {
        if year >= 0 {
            let digits = String(year)
            if year <= 9999 {
                return String(repeating: "0", count: 4 - digits.count) + digits
            }
            return "+" + digits
        }

        let magnitude = Self.magnitude(of: year)
        let digits = String(magnitude)
        return "-" + String(repeating: "0", count: max(0, 4 - digits.count)) + digits
    }

    private static func foundationYear(for year: Int64) -> (era: Int, year: Int)? {
        if year > 0 {
            guard let foundationYear = Int(exactly: year) else {
                return nil
            }
            return (1, foundationYear)
        }

        let magnitude = Self.magnitude(of: year)
        let (foundationMagnitude, overflow) = magnitude.addingReportingOverflow(1)
        guard !overflow, let foundationYear = Int(exactly: foundationMagnitude) else {
            return nil
        }
        return (0, foundationYear)
    }

    private static func magnitude(of value: Int64) -> UInt64 {
        value.magnitude
    }

    private static func astronomicalYear(era: Int, foundationYear: Int) -> Int64? {
        guard foundationYear > 0, let year = Int64(exactly: foundationYear) else {
            return nil
        }

        switch era {
        case 1:
            return year
        case 0:
            let result = Int64(1).subtractingReportingOverflow(year)
            return result.overflow ? nil : result.partialValue
        default:
            return nil
        }
    }
}
