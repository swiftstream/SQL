@testable import SQL
import Foundation
import Testing

@Suite("PureDate tests")
struct PureDateTests {
    @Test("PureDate validates ordinary dates and proleptic Gregorian leap years")
    func validationAndLeapYears() {
        #expect(PureDate(year: 2026, month: 9, day: 4) != nil)
        #expect(PureDate(year: 2026, month: 13, day: 1) == nil)
        #expect(PureDate(year: 2026, month: 4, day: 31) == nil)
        #expect(PureDate(year: 2026, month: 0, day: 1) == nil)

        #expect(PureDate(year: 2024, month: 2, day: 29) != nil)
        #expect(PureDate(year: 1900, month: 2, day: 29) == nil)
        #expect(PureDate(year: 2000, month: 2, day: 29) != nil)
        #expect(PureDate(year: 0, month: 2, day: 29) != nil)
        #expect(PureDate(year: -100, month: 2, day: 29) == nil)
        #expect(PureDate(year: -400, month: 2, day: 29) != nil)
    }

    @Test("PureDate uses canonical astronomical-year strings")
    func canonicalStrings() {
        let examples: [(String, Int64)] = [
            ("0001-01-01", 1),
            ("0000-01-01", 0),
            ("-0001-01-01", -1),
            ("+10000-01-01", 10_000)
        ]

        for (string, year) in examples {
            let value = PureDate(string)
            #expect(value?.year == year)
            #expect(value?.description == string)
        }

        #expect(PureDate("+09999-01-01") == nil)
        #expect(PureDate("-0000-01-01") == nil)
        #expect(PureDate("-00001-01-01") == nil)
        #expect(PureDate("0001-1-01") == nil)
        #expect(PureDate("0001-01-1") == nil)
        #expect(PureDate("0001/01/01") == nil)
        #expect(PureDate("0001-02-29") == nil)
    }

    @Test("PureDate formats and parses Int64 year boundaries")
    func extremeYears() {
        let minimum = PureDate(year: Int64.min, month: 1, day: 1)
        #expect(minimum?.description == "-9223372036854775808-01-01")
        if let minimum {
            #expect(PureDate(minimum.description) == minimum)
        }

        let maximum = PureDate(year: Int64.max, month: 12, day: 31)
        #expect(maximum?.description == "+9223372036854775807-12-31")
        if let maximum {
            #expect(PureDate(maximum.description) == maximum)
        }
    }

    @Test("PureDate infinities have ordered special-value semantics")
    func infinities() throws {
        let finite = try #require(PureDate(year: 2026, month: 9, day: 4))
        #expect(PureDate.negativeInfinity < finite)
        #expect(finite < PureDate.positiveInfinity)
        #expect(PureDate.negativeInfinity < PureDate.positiveInfinity)
        #expect(PureDate.negativeInfinity == PureDate("-infinity"))
        #expect(PureDate.positiveInfinity == PureDate("infinity"))
        #expect(!PureDate.negativeInfinity.isFinite)
        #expect(!PureDate.positiveInfinity.isFinite)
        #expect(PureDate.negativeInfinity.year == nil)
        #expect(PureDate.negativeInfinity.month == nil)
        #expect(PureDate.negativeInfinity.day == nil)
        #expect(PureDate.positiveInfinity.year == nil)
    }

    @Test("PureDate Codable is the exact canonical single string")
    func codable() throws {
        let values = [
            PureDate(year: 2026, month: 9, day: 4),
            PureDate(year: 0, month: 1, day: 1),
            PureDate.negativeInfinity,
            PureDate.positiveInfinity
        ].compactMap { $0 }

        for value in values {
            let encoded = try JSONEncoder().encode(value)
            #expect(String(data: encoded, encoding: .utf8) == "\"\(value.description)\"")
            #expect(try JSONDecoder().decode(PureDate.self, from: encoded) == value)
        }

        let invalid = Data(#""0001-02-29""#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(PureDate.self, from: invalid)
        }
    }

    @Test("PureDate Foundation interop requires Gregorian calendar and round-trips civil components")
    func foundationInterop() throws {
        let timeZone = try #require(TimeZone(identifier: "UTC"))
        let calendar = Calendar(identifier: .gregorian)
        let value = try #require(PureDate(year: 2026, month: 9, day: 4))
        let date = try #require(value.date(calendar: calendar, timeZone: timeZone))

        #expect(PureDate(date: date, calendar: calendar, timeZone: timeZone) == value)
        var roundTripCalendar = calendar
        roundTripCalendar.timeZone = timeZone
        let components = roundTripCalendar.dateComponents([.hour, .minute, .second], from: date)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
        #expect(PureDate.positiveInfinity.date(calendar: calendar, timeZone: timeZone) == nil)

        let nonGregorian = Calendar(identifier: .buddhist)
        #expect(value.date(calendar: nonGregorian, timeZone: timeZone) == nil)
        #expect(PureDate(date: date, calendar: nonGregorian, timeZone: timeZone) == nil)
    }

    @Test("PureDate Foundation interop preserves astronomical year mapping")
    func foundationAstronomicalYears() throws {
        let timeZone = try #require(TimeZone(identifier: "UTC"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let cases: [(astronomicalYear: Int64, era: Int, year: Int)] = [
            (1, 1, 1),
            (0, 0, 1),
            (-1, 0, 2)
        ]

        for valueCase in cases {
            let value = try #require(
                PureDate(year: valueCase.astronomicalYear, month: 1, day: 1)
            )
            let date = try #require(value.date(calendar: calendar, timeZone: timeZone))
            let components = calendar.dateComponents([.era, .year], from: date)

            #expect(components.era == valueCase.era)
            #expect(components.year == valueCase.year)
            #expect(PureDate(date: date, calendar: calendar, timeZone: timeZone) == value)
        }

        let minimum = try #require(PureDate(year: Int64.min, month: 1, day: 1))
        #expect(minimum.date(calendar: calendar, timeZone: timeZone) == nil)
    }

    @Test("PureDate rejects a nonexistent local midnight")
    func rejectsNonexistentLocalMidnight() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Sao_Paulo"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let value = try #require(PureDate(year: 2018, month: 11, day: 4))

        #expect(value.date(calendar: calendar, timeZone: timeZone) == nil)
    }
}
