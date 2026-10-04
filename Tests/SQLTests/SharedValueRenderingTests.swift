import Foundation
import Testing
@testable import SQL

private final class SharedValueFallbackDialect: SQLDialect {
    override func stringValue(_ value: String) -> String {
        "fallback[\(value)]"
    }
}

@Suite("Shared value rendering")
struct SharedValueRenderingTests {
    private func sampleDate() throws -> PureDate {
        try #require(PureDate(year: 2026, month: 9, day: 4))
    }

    private func sampleTime() throws -> PureTime {
        try #require(PureTime(hour: 12, minute: 34, second: 56, nanosecond: 123_456_789))
    }

    private func sampleDateTime() throws -> DateTime {
        try #require(DateTime(
            year: 2026,
            month: 9,
            day: 4,
            hour: 12,
            minute: 34,
            second: 56,
            nanosecond: 123_456_789
        ))
    }

    private func expectMySQLUnsupported(
        _ rendering: String,
        family: String,
        canonicalValue: String
    ) {
        let marker = "<mysql_unsupported_\(family):\(canonicalValue)>"
        #expect(rendering == marker)
        #expect(rendering.hasPrefix("<mysql_unsupported_\(family):"))
        #expect(rendering.contains(canonicalValue))
        #expect(!rendering.contains("CAST("))
        #expect(!rendering.contains("NULL"))
        #expect(!rendering.contains("0000-00-00"))
    }

    @Test("Representative values use exact dialect-specific plain forms")
    func representativeValuesRenderAcrossDialects() throws {
        let date = try sampleDate()
        let time = try sampleTime()
        let dateTime = try sampleDateTime()
        let interval = Interval(months: 2, days: -3, microseconds: 4)

        #expect(date.prepare(.psql).plain == "DATE '2026-09-04'")
        #expect(time.prepare(.psql).plain == "TIME '12:34:56.123456789'")
        #expect(PureTime.endOfDay.prepare(.psql).plain == "TIME '24:00:00'")
        #expect(dateTime.prepare(.psql).plain == "TIMESTAMP '2026-09-04 12:34:56.123456789'")
        #expect(interval.prepare(.psql).plain == "INTERVAL '2 months -3 days 4 microseconds'")

        #expect(date.prepare(.duck).plain == "DATE '2026-09-04'")
        #expect(time.prepare(.duck).plain == "CAST('12:34:56.123456789' AS TIME_NS)")
        #expect(PureTime.endOfDay.prepare(.duck).plain == "CAST('24:00:00' AS TIME_NS)")
        #expect(dateTime.prepare(.duck).plain == "CAST('2026-09-04 12:34:56.123456789' AS TIMESTAMP_NS)")
        #expect(interval.prepare(.duck).plain == "INTERVAL '2 months -3 days 4 microseconds'")

        #expect(date.prepare(.mysql).plain == "CAST('2026-09-04' AS DATE)")
        expectMySQLUnsupported(
            time.prepare(.mysql).plain,
            family: "pure_time",
            canonicalValue: time.description
        )
        #expect(PureTime.endOfDay.prepare(.mysql).plain == "CAST('24:00:00' AS TIME)")
        expectMySQLUnsupported(
            dateTime.prepare(.mysql).plain,
            family: "date_time",
            canonicalValue: dateTime.description
        )
        #expect(interval.prepare(.mysql).plain == "'2 months -3 days 4 microseconds'")
    }

    @Test("Duck removes only the positive extended-year input sign")
    func duckExtendedPositiveYearsRenderWithoutCanonicalSign() throws {
        let ordinary = try #require(PureDate(year: 9999, month: 12, day: 31))
        let extended = try #require(PureDate(year: 10_000, month: 1, day: 1))
        let extendedDateTime = try #require(DateTime(
            year: 10_000,
            month: 1,
            day: 1,
            hour: 12,
            minute: 34,
            second: 56
        ))

        #expect(ordinary.prepare(.duck).plain == "DATE '9999-12-31'")
        #expect(extended.description == "+10000-01-01")
        #expect(extended.prepare(.duck).plain == "DATE '10000-01-01'")
        #expect(extendedDateTime.description == "+10000-01-01T12:34:56")
        #expect(
            extendedDateTime.prepare(.duck).plain
                == "CAST('10000-01-01 12:34:56' AS TIMESTAMP_NS)"
        )
    }

    @Test("Astronomical years preserve year zero and year minus one")
    func astronomicalYearsRenderWithoutOffByOne() throws {
        let yearZeroDate = try #require(PureDate(year: 0, month: 1, day: 1))
        let yearMinusOneDate = try #require(PureDate(year: -1, month: 1, day: 1))
        let yearZeroDateTime = try #require(DateTime(
            year: 0,
            month: 1,
            day: 1,
            hour: 12,
            minute: 34,
            second: 56
        ))

        #expect(yearZeroDate.prepare(.psql).plain == "DATE '0001-01-01 BC'")
        #expect(yearMinusOneDate.prepare(.psql).plain == "DATE '0002-01-01 BC'")
        #expect(yearZeroDate.prepare(.duck).plain == "DATE '0001-01-01 (BC)'")
        #expect(yearMinusOneDate.prepare(.duck).plain == "DATE '0002-01-01 (BC)'")
        #expect(yearZeroDateTime.prepare(.psql).plain == "TIMESTAMP '0001-01-01 12:34:56 BC'")
        #expect(yearZeroDateTime.prepare(.duck).plain == "CAST('0001-01-01 (BC) 12:34:56' AS TIMESTAMP_NS)")
    }

    @Test("Temporal and PostgreSQL interval infinities remain explicit")
    func infinitiesRenderExplicitly() {
        #expect(PureDate.positiveInfinity.prepare(.psql).plain == "DATE 'infinity'")
        #expect(PureDate.negativeInfinity.prepare(.psql).plain == "DATE '-infinity'")
        #expect(DateTime.positiveInfinity.prepare(.psql).plain == "TIMESTAMP 'infinity'")
        #expect(DateTime.negativeInfinity.prepare(.psql).plain == "TIMESTAMP '-infinity'")
        #expect(Interval.positiveInfinity.prepare(.psql).plain == "INTERVAL 'infinity'")
        #expect(Interval.negativeInfinity.prepare(.psql).plain == "INTERVAL '-infinity'")

        #expect(PureDate.positiveInfinity.prepare(.duck).plain == "DATE 'infinity'")
        #expect(PureDate.negativeInfinity.prepare(.duck).plain == "DATE '-infinity'")
        #expect(DateTime.positiveInfinity.prepare(.duck).plain == "CAST('infinity' AS TIMESTAMP_NS)")
        #expect(DateTime.negativeInfinity.prepare(.duck).plain == "CAST('-infinity' AS TIMESTAMP_NS)")
    }

    @Test("Duck interval infinities are unsupported, never finite substitutions")
    func duckIntervalInfinityIsUnsupported() {
        let positive = Interval.positiveInfinity.prepare(.duck).plain
        let negative = Interval.negativeInfinity.prepare(.duck).plain

        #expect(positive == "'infinity'")
        #expect(negative == "'-infinity'")
        #expect(!positive.contains("months"))
        #expect(!negative.contains("months"))
        #expect(positive != "INTERVAL '0 months 0 days 0 microseconds'")
        #expect(negative != "INTERVAL '0 months 0 days 0 microseconds'")
    }

    @Test("MySQL PureDate renders only its guaranteed finite range")
    func mysqlPureDateRenderingUsesGuaranteedRange() throws {
        let ordinary = try sampleDate()
        let lower = try #require(PureDate(year: 1000, month: 1, day: 1))
        let upper = try #require(PureDate(year: 9999, month: 12, day: 31))

        #expect(ordinary.prepare(.mysql).plain == "CAST('2026-09-04' AS DATE)")
        #expect(lower.prepare(.mysql).plain == "CAST('1000-01-01' AS DATE)")
        #expect(upper.prepare(.mysql).plain == "CAST('9999-12-31' AS DATE)")

        let unsupported = [
            try #require(PureDate(year: 999, month: 12, day: 31)),
            try #require(PureDate(year: 0, month: 1, day: 1)),
            try #require(PureDate(year: -1, month: 1, day: 1)),
            try #require(PureDate(year: 10_000, month: 1, day: 1)),
            PureDate.positiveInfinity,
            PureDate.negativeInfinity
        ]

        for value in unsupported {
            expectMySQLUnsupported(
                value.prepare(.mysql).plain,
                family: "pure_date",
                canonicalValue: value.description
            )
        }
    }

    @Test("MySQL PureTime preserves only exact microsecond fractions")
    func mysqlPureTimeRenderingUsesExactPrecision() throws {
        let zeroFraction = try #require(PureTime(hour: 12, minute: 34, second: 56))
        let microsecondExact = try #require(PureTime(
            hour: 12,
            minute: 34,
            second: 56,
            nanosecond: 123_456_000
        ))
        let nonMicrosecond = try sampleTime()
        let maximum = try #require(PureTime(
            hour: 23,
            minute: 59,
            second: 59,
            nanosecond: 999_999_999
        ))

        #expect(zeroFraction.prepare(.mysql).plain == "CAST('12:34:56' AS TIME)")
        #expect(microsecondExact.prepare(.mysql).plain == "CAST('12:34:56.123456' AS TIME(6))")
        #expect(PureTime.endOfDay.prepare(.mysql).plain == "CAST('24:00:00' AS TIME)")

        for value in [nonMicrosecond, maximum] {
            expectMySQLUnsupported(
                value.prepare(.mysql).plain,
                family: "pure_time",
                canonicalValue: value.description
            )
        }
    }

    @Test("MySQL DateTime preserves exact range and fractional precision")
    func mysqlDateTimeRenderingUsesExactRangeAndPrecision() throws {
        let zeroFraction = try #require(DateTime(
            year: 2026,
            month: 9,
            day: 4,
            hour: 12,
            minute: 34,
            second: 56
        ))
        let microsecondExact = try #require(DateTime(
            year: 2026,
            month: 9,
            day: 4,
            hour: 12,
            minute: 34,
            second: 56,
            nanosecond: 123_456_000
        ))
        let nonMicrosecond = try sampleDateTime()

        let zeroOutput = zeroFraction.prepare(.mysql).plain
        let microsecondOutput = microsecondExact.prepare(.mysql).plain
        #expect(zeroOutput == "CAST('2026-09-04 12:34:56' AS DATETIME)")
        #expect(microsecondOutput == "CAST('2026-09-04 12:34:56.123456' AS DATETIME(6))")
        #expect(!zeroOutput.contains("TIMESTAMP"))
        #expect(!microsecondOutput.contains("TIMESTAMP"))

        let unsupported = [
            nonMicrosecond,
            try #require(DateTime(
                year: 999,
                month: 12,
                day: 31,
                hour: 23,
                minute: 59,
                second: 59
            )),
            try #require(DateTime(
                year: 0,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0
            )),
            try #require(DateTime(
                year: 10_000,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0
            )),
            DateTime.positiveInfinity,
            DateTime.negativeInfinity
        ]

        for value in unsupported {
            expectMySQLUnsupported(
                value.prepare(.mysql).plain,
                family: "date_time",
                canonicalValue: value.description
            )
        }
    }

    @Test("Default and custom dialect fallbacks preserve all shared value text")
    func fallbackDialectsRemainSafeAndComplete() throws {
        let date = try sampleDate()
        let time = try sampleTime()
        let dateTime = try sampleDateTime()
        let interval = Interval(months: 2, days: -3, microseconds: 4)
        let fallback = SQLDialect()
        let custom = SharedValueFallbackDialect()

        for value in [
            date.prepare(fallback).plain,
            time.prepare(fallback).plain,
            dateTime.prepare(fallback).plain,
            interval.prepare(fallback).plain
        ] {
            #expect(!value.contains("<unsafe value>"))
        }
        #expect(date.prepare(fallback).plain == "'2026-09-04'")
        #expect(time.prepare(fallback).plain == "'12:34:56.123456789'")
        #expect(dateTime.prepare(fallback).plain == "'2026-09-04T12:34:56.123456789'")
        #expect(interval.prepare(fallback).plain == "'2 months -3 days 4 microseconds'")
        #expect(interval.prepare(custom).plain == "fallback[2 months -3 days 4 microseconds]")
        #expect(Interval.negativeInfinity.prepare(fallback).plain == "'-infinity'")
    }

    @Test("Foundation Date keeps its existing date-part and Duck formatting")
    func foundationDateBehaviorRemainsExisting() {
        let foundationDate = Date(timeIntervalSince1970: 1_577_934_245.123456)
        #expect(foundationDate.parts.count == 1)
        #expect(foundationDate.parts.first is SwifQLPartDate)
        #expect(
            foundationDate.prepare(.duck).plain
                == "TIMESTAMPTZ '2020-01-02 03:04:05.123456+00:00'"
        )
    }
}
