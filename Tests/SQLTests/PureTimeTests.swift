@testable import SQL
import Foundation
import Testing

@Suite("PureTime tests")
struct PureTimeTests {
    @Test("PureTime preserves midnight and the exact end-of-day endpoint")
    func endpoints() throws {
        #expect(PureTime.midnight.nanosecondsSinceMidnight == 0)
        #expect(PureTime.midnight.description == "00:00:00")
        #expect(PureTime.midnight.hour == 0)
        #expect(PureTime.midnight.minute == 0)
        #expect(PureTime.midnight.second == 0)
        #expect(PureTime.midnight.nanosecond == 0)

        let maximumOrdinary = try #require(
            PureTime(hour: 23, minute: 59, second: 59, nanosecond: 999_999_999)
        )
        #expect(maximumOrdinary.nanosecondsSinceMidnight == 86_399_999_999_999)
        #expect(maximumOrdinary.description == "23:59:59.999999999")

        #expect(PureTime.endOfDay != PureTime.midnight)
        #expect(PureTime.endOfDay.nanosecondsSinceMidnight == 86_400_000_000_000)
        #expect(PureTime.endOfDay.description == "24:00:00")
        #expect(PureTime.midnight < maximumOrdinary)
        #expect(maximumOrdinary < PureTime.endOfDay)
    }

    @Test("PureTime rejects values outside the civil-day domain")
    func invalidValues() {
        #expect(PureTime(hour: 24, minute: 0, second: 0, nanosecond: 1) == nil)
        #expect(PureTime(hour: 24, minute: 1) == nil)
        #expect(PureTime(hour: 25, minute: 0) == nil)
        #expect(PureTime(hour: -1, minute: 0) == nil)
        #expect(PureTime(hour: 23, minute: 59, second: 60) == nil)
        #expect(PureTime(hour: 23, minute: 59, nanosecond: 1_000_000_000) == nil)
        #expect(PureTime(nanosecondsSinceMidnight: -1) == nil)
        #expect(PureTime(nanosecondsSinceMidnight: 86_400_000_000_001) == nil)
        #expect(PureTime("24:00:00.000000001") == nil)
        #expect(PureTime("23:59:60") == nil)
    }

    @Test("PureTime parses nanosecond fractions and emits canonical trimming")
    func fractions() {
        let examples: [(String, Int, String)] = [
            ("12:34:56.1", 100_000_000, "12:34:56.1"),
            ("12:34:56.12", 120_000_000, "12:34:56.12"),
            ("12:34:56.123", 123_000_000, "12:34:56.123"),
            ("12:34:56.1234", 123_400_000, "12:34:56.1234"),
            ("12:34:56.12345", 123_450_000, "12:34:56.12345"),
            ("12:34:56.123456", 123_456_000, "12:34:56.123456"),
            ("12:34:56.1234567", 123_456_700, "12:34:56.1234567"),
            ("12:34:56.12345678", 123_456_780, "12:34:56.12345678"),
            ("12:34:56.123456789", 123_456_789, "12:34:56.123456789"),
            ("12:34:56.1200", 120_000_000, "12:34:56.12")
        ]

        for (input, nanosecond, canonical) in examples {
            let value = PureTime(input)
            #expect(value?.nanosecond == nanosecond)
            #expect(value?.description == canonical)
        }

        #expect(PureTime("12:34:56.1234567890") == nil)
        #expect(PureTime("12:34:56+01:00") == nil)
        #expect(PureTime("-01:00:00") == nil)
        #expect(PureTime("01:00:00Z") == nil)
        #expect(PureTime("100:00:00") == nil)
    }

    @Test("PureTime Codable is the exact canonical single string")
    func codable() throws {
        let values = [
            PureTime.midnight,
            try #require(PureTime(hour: 12, minute: 34, second: 56, nanosecond: 120_000_000)),
            PureTime.endOfDay
        ]

        for value in values {
            let encoded = try JSONEncoder().encode(value)
            #expect(String(data: encoded, encoding: .utf8) == "\"\(value.description)\"")
            #expect(try JSONDecoder().decode(PureTime.self, from: encoded) == value)
        }
    }
}
