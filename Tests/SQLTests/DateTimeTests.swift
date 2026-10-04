@testable import SQL
import Foundation
import Testing

@Suite("DateTime tests")
struct DateTimeTests {
    @Test("DateTime exposes finite civil components")
    func finiteComponents() throws {
        let value = try #require(
            DateTime(
                year: 2026,
                month: 9,
                day: 4,
                hour: 12,
                minute: 34,
                second: 56,
                nanosecond: 123_456_789
            )
        )

        #expect(value.isFinite)
        #expect(value.date == PureDate(year: 2026, month: 9, day: 4))
        #expect(value.time?.description == "12:34:56.123456789")
        #expect(value.year == 2026)
        #expect(value.month == 9)
        #expect(value.day == 4)
        #expect(value.hour == 12)
        #expect(value.minute == 34)
        #expect(value.second == 56)
        #expect(value.nanosecond == 123_456_789)
        #expect(value.description == "2026-09-04T12:34:56.123456789")
    }

    @Test("DateTime canonicalizes exact end-of-day to the next Gregorian date")
    func endOfDayCanonicalization() throws {
        let date = try #require(PureDate(year: 2026, month: 1, day: 1))
        let value = try #require(DateTime(date: date, time: .endOfDay))

        #expect(value.date == PureDate(year: 2026, month: 1, day: 2))
        #expect(value.time == PureTime.midnight)
        #expect(value.description == "2026-01-02T00:00:00")
    }

    @Test("DateTime end-of-day canonicalization crosses month, year, and leap boundaries")
    func endOfDayBoundaries() throws {
        let cases: [(PureDate, PureDate)] = [
            (
                try #require(PureDate(year: 2024, month: 2, day: 29)),
                try #require(PureDate(year: 2024, month: 3, day: 1))
            ),
            (
                try #require(PureDate(year: 2024, month: 12, day: 31)),
                try #require(PureDate(year: 2025, month: 1, day: 1))
            ),
            (
                try #require(PureDate(year: 0, month: 12, day: 31)),
                try #require(PureDate(year: 1, month: 1, day: 1))
            )
        ]

        for (date, expectedDate) in cases {
            let value = try #require(DateTime(date: date, time: .endOfDay))
            #expect(value.date == expectedDate)
            #expect(value.time == PureTime.midnight)
        }
    }

    @Test("DateTime rejects end-of-day overflow at Int64.max year")
    func endOfDayOverflow() throws {
        let date = try #require(PureDate(year: Int64.max, month: 12, day: 31))
        #expect(DateTime(date: date, time: .endOfDay) == nil)
        #expect(DateTime(year: Int64.max, month: 12, day: 31, hour: 24, minute: 0) == nil)
    }

    @Test("DateTime infinities have ordered special-value semantics")
    func infinities() throws {
        let finite = try #require(
            DateTime(year: 2026, month: 9, day: 4, hour: 0, minute: 0)
        )
        #expect(DateTime.negativeInfinity < finite)
        #expect(finite < DateTime.positiveInfinity)
        #expect(DateTime.negativeInfinity < DateTime.positiveInfinity)
        #expect(DateTime.negativeInfinity == DateTime("-infinity"))
        #expect(DateTime.positiveInfinity == DateTime("infinity"))
        #expect(!DateTime.negativeInfinity.isFinite)
        #expect(!DateTime.positiveInfinity.isFinite)
        #expect(DateTime.negativeInfinity.date == nil)
        #expect(DateTime.negativeInfinity.time == nil)
        #expect(DateTime.negativeInfinity.year == nil)
        #expect(DateTime.negativeInfinity.hour == nil)
    }

    @Test("DateTime parses and encodes the canonical civil grammar")
    func canonicalStringsAndCodable() throws {
        let examples: [(String, String)] = [
            ("2026-09-04T12:34:56", "2026-09-04T12:34:56"),
            ("0000-01-01T00:00:00", "0000-01-01T00:00:00"),
            ("-0001-01-01T23:59:59.123456789", "-0001-01-01T23:59:59.123456789"),
            ("2026-01-01T24:00:00", "2026-01-02T00:00:00")
        ]

        for (input, canonical) in examples {
            let value = try #require(DateTime(input))
            #expect(value.description == canonical)
            let encoded = try JSONEncoder().encode(value)
            #expect(String(data: encoded, encoding: .utf8) == "\"\(canonical)\"")
            #expect(try JSONDecoder().decode(DateTime.self, from: encoded) == value)
        }

        #expect(DateTime("2026-09-04 12:34:56") == nil)
        #expect(DateTime("2026-09-04T12:34:56Z") == nil)
        #expect(DateTime("2026-09-04T12:34:56+01:00") == nil)
        #expect(DateTime("2026-09-04T12:34:56 America/New_York") == nil)
    }

    @Test("DateTime Foundation interop round-trips an ordinary explicit local time")
    func ordinaryFoundationInterop() throws {
        let timeZone = try #require(TimeZone(identifier: "America/New_York"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let value = try #require(
            DateTime(year: 2026, month: 9, day: 4, hour: 12, minute: 34, second: 56)
        )
        let date = try #require(value.date(calendar: calendar, timeZone: timeZone))

        #expect(DateTime(date: date, calendar: calendar, timeZone: timeZone) == value)
        #expect(DateTime.positiveInfinity.date(calendar: calendar, timeZone: timeZone) == nil)
        #expect(value.date(calendar: Calendar(identifier: .buddhist), timeZone: timeZone) == nil)
    }

    @Test("DateTime Foundation interop preserves astronomical years")
    func foundationAstronomicalYears() throws {
        let timeZone = try #require(TimeZone(identifier: "UTC"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let cases: [(astronomicalYear: Int64, era: Int, year: Int)] = [
            (0, 0, 1),
            (-1, 0, 2)
        ]

        for valueCase in cases {
            let value = try #require(
                DateTime(
                    year: valueCase.astronomicalYear,
                    month: 1,
                    day: 1,
                    hour: 12,
                    minute: 34,
                    second: 56
                )
            )
            let date = try #require(value.date(calendar: calendar, timeZone: timeZone))
            let components = calendar.dateComponents(
                [.era, .year, .month, .day, .hour, .minute, .second],
                from: date
            )

            #expect(components.era == valueCase.era)
            #expect(components.year == valueCase.year)
            #expect(components.month == 1)
            #expect(components.day == 1)
            #expect(components.hour == 12)
            #expect(components.minute == 34)
            #expect(components.second == 56)
            #expect(DateTime(date: date, calendar: calendar, timeZone: timeZone) == value)
        }

        let minimum = try #require(
            DateTime(year: Int64.min, month: 1, day: 1, hour: 12, minute: 34)
        )
        #expect(minimum.date(calendar: calendar, timeZone: timeZone) == nil)
    }

    @Test("DateTime rejects nonexistent and ambiguous local civil times")
    func daylightSavingTransitions() throws {
        let timeZone = try #require(TimeZone(identifier: "America/New_York"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let nonexistent = try #require(
            DateTime(year: 2024, month: 3, day: 10, hour: 2, minute: 30)
        )
        #expect(nonexistent.date(calendar: calendar, timeZone: timeZone) == nil)

        let ambiguous = try #require(
            DateTime(year: 2024, month: 11, day: 3, hour: 1, minute: 30)
        )
        #expect(ambiguous.date(calendar: calendar, timeZone: timeZone) == nil)

        var repeatedComponents = DateComponents()
        repeatedComponents.timeZone = timeZone
        repeatedComponents.year = 2024
        repeatedComponents.month = 11
        repeatedComponents.day = 3
        repeatedComponents.hour = 1
        repeatedComponents.minute = 30
        let repeatedDate = try #require(calendar.date(from: repeatedComponents))
        let extracted = try #require(
            DateTime(date: repeatedDate, calendar: calendar, timeZone: timeZone)
        )
        #expect(extracted == ambiguous)
    }
}
