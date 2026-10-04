import Foundation

/// A timezone-free civil date and time composed from `PureDate` and `PureTime`.
///
/// `DateTime` is not `Foundation.Date` and does not identify an instant. It
/// has no embedded time zone; conversion to or from `Foundation.Date` requires
/// an explicit Gregorian `Calendar` and `TimeZone`. A supplied exact
/// `PureTime.endOfDay` is canonicalized to the following date's midnight, and
/// the two infinity values are special civil-domain states that cannot be
/// converted to `Foundation.Date`.
public struct DateTime: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    private enum Storage: Sendable, Hashable {
        case finite(date: PureDate, time: PureTime)
        case positiveInfinity
        case negativeInfinity
    }

    private static let civilComponents: Set<Calendar.Component> = [
        .era, .year, .month, .day, .hour, .minute, .second, .nanosecond
    ]

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    /// Creates a finite civil date and time.
    ///
    /// The date must be finite. An exact `24:00:00` time is accepted and
    /// canonicalized to the next Gregorian date at midnight; that checked
    /// advance returns `nil` at the shared `Int64` year boundary.
    public init?(date: PureDate, time: PureTime) {
        guard date.isFinite else {
            return nil
        }

        if time == .endOfDay {
            guard let nextDate = date.addingOneDay() else {
                return nil
            }
            storage = .finite(date: nextDate, time: .midnight)
        } else {
            storage = .finite(date: date, time: time)
        }
    }

    /// Creates a finite civil date and time from its components.
    ///
    /// This is timezone-free civil data, not an instant. Hour 24 is accepted
    /// only as `24:00:00` and follows the same checked next-day
    /// canonicalization as `init(date:time:)`.
    public init?(
        year: Int64,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int = 0,
        nanosecond: Int = 0
    ) {
        guard let date = PureDate(year: year, month: month, day: day),
              let time = PureTime(
                hour: hour,
                minute: minute,
                second: second,
                nanosecond: nanosecond
              ) else {
            return nil
        }
        self.init(date: date, time: time)
    }

    /// Parses the canonical `<PureDate>T<PureTime>` grammar.
    ///
    /// Zone names, numeric offsets, `Z`, and whitespace are deliberately not
    /// accepted because they would turn this civil value into instant syntax.
    /// A canonical `24:00:00` component is accepted and normalized to the next
    /// date before storage.
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

        let components = string.split(separator: "T", omittingEmptySubsequences: false)
        guard components.count == 2,
              let date = PureDate(String(components[0])),
              let time = PureTime(String(components[1])) else {
            return nil
        }
        self.init(date: date, time: time)
    }

    /// A civil date-time value greater than every finite value.
    public static let positiveInfinity = Self(storage: .positiveInfinity)

    /// A civil date-time value less than every finite value.
    public static let negativeInfinity = Self(storage: .negativeInfinity)

    /// Whether this value contains finite civil date and time components.
    public var isFinite: Bool {
        if case .finite = storage {
            return true
        }
        return false
    }

    /// The finite civil date, or `nil` for an infinity.
    public var date: PureDate? {
        guard case let .finite(date, _) = storage else {
            return nil
        }
        return date
    }

    /// The finite canonical civil time, or `nil` for an infinity.
    public var time: PureTime? {
        guard case let .finite(_, time) = storage else {
            return nil
        }
        return time
    }

    /// The finite astronomical year, or `nil` for an infinity.
    public var year: Int64? {
        date?.year ?? nil
    }

    /// The finite month, or `nil` for an infinity.
    public var month: Int? {
        date?.month ?? nil
    }

    /// The finite day of month, or `nil` for an infinity.
    public var day: Int? {
        date?.day ?? nil
    }

    /// The finite hour, or `nil` for an infinity.
    public var hour: Int? {
        time?.hour ?? nil
    }

    /// The finite minute, or `nil` for an infinity.
    public var minute: Int? {
        time?.minute ?? nil
    }

    /// The finite second, or `nil` for an infinity.
    public var second: Int? {
        time?.second ?? nil
    }

    /// The finite nanosecond fraction, or `nil` for an infinity.
    public var nanosecond: Int? {
        time?.nanosecond ?? nil
    }

    /// The canonical `<PureDate>T<PureTime>` spelling used by `Codable`.
    public var description: String {
        switch storage {
        case .positiveInfinity:
            return "infinity"
        case .negativeInfinity:
            return "-infinity"
        case let .finite(date, time):
            return "\(date.description)T\(time.description)"
        }
    }

    /// Creates a `Foundation.Date` only when the civil time is one unique,
    /// exactly representable local time in the supplied Gregorian calendar and
    /// time zone.
    ///
    /// Nonexistent daylight-saving times, repeated/ambiguous daylight-saving
    /// times, infinities, Foundation range limits, and component rounding all
    /// return `nil`; no occurrence is selected implicitly.
    public func date(calendar: Calendar, timeZone: TimeZone) -> Foundation.Date? {
        guard case let .finite(date, time) = storage,
              calendar.identifier == .gregorian,
              let year = date.year,
              let month = date.month,
              let day = date.day,
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
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        components.nanosecond = time.nanosecond

        guard let candidate = calendar.date(from: components),
              Self.matches(
                calendar.dateComponents(Self.civilComponents, from: candidate),
                requested: components
              ) else {
            return nil
        }

        let searchStart = candidate.addingTimeInterval(-172_800)
        var matchingComponents = components
        matchingComponents.timeZone = nil
        matchingComponents.second = nil
        matchingComponents.nanosecond = nil
        guard let first = calendar.nextDate(
            after: searchStart,
            matching: matchingComponents,
            matchingPolicy: .strict,
            repeatedTimePolicy: .first,
            direction: .forward
        ),
        let last = calendar.nextDate(
            after: searchStart,
            matching: matchingComponents,
            matchingPolicy: .strict,
            repeatedTimePolicy: .last,
            direction: .forward
        ),
        first == last else {
            return nil
        }

        return candidate
    }

    /// Creates a civil date-time from a `Foundation.Date` using an explicit
    /// Gregorian calendar and time zone.
    ///
    /// The local civil components are copied exactly; the source instant's
    /// time-zone occurrence is intentionally not retained in the resulting
    /// timezone-free identity. Values whose components cannot be represented
    /// by `DateTime` return `nil`.
    public init?(date: Foundation.Date, calendar: Calendar, timeZone: TimeZone) {
        guard calendar.identifier == .gregorian else {
            return nil
        }

        var calendar = calendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents(Self.civilComponents, from: date)
        guard let pureDate = PureDate(date: date, calendar: calendar, timeZone: timeZone),
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second,
              let nanosecond = components.nanosecond,
              let time = PureTime(
                hour: hour,
                minute: minute,
                second: second,
                nanosecond: nanosecond
              ) else {
            return nil
        }

        self.init(date: pureDate, time: time)
    }

    /// Encodes the canonical single date-time string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// Decodes the canonical single date-time string.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = Self(string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid canonical DateTime string"
            )
        }
        self = value
    }

    /// Compares infinities and finite civil values by date, then time.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        let lhsRank = lhs.orderingRank
        let rhsRank = rhs.orderingRank
        guard lhsRank == rhsRank else {
            return lhsRank < rhsRank
        }

        guard case let .finite(lhsDate, lhsTime) = lhs.storage,
              case let .finite(rhsDate, rhsTime) = rhs.storage else {
            return false
        }
        if lhsDate != rhsDate {
            return lhsDate < rhsDate
        }
        return lhsTime < rhsTime
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

    private static func matches(_ actual: DateComponents, requested: DateComponents) -> Bool {
        actual.era == requested.era
            && actual.year == requested.year
            && actual.month == requested.month
            && actual.day == requested.day
            && actual.hour == requested.hour
            && actual.minute == requested.minute
            && actual.second == requested.second
            && actual.nanosecond == requested.nanosecond
    }
}
