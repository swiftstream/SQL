import Foundation
import Testing
@testable import SQL

@Suite("Shared value binding")
struct SharedValueBindingTests {
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

    private func sampleInterval() -> Interval {
        Interval(months: 2, days: -3, microseconds: 4)
    }

    @Test("Each shared value is one ordinary unsafe value part")
    func eachValueProducesOneUnsafePart() throws {
        let date = try sampleDate()
        let time = try sampleTime()
        let dateTime = try sampleDateTime()
        let interval = sampleInterval()

        let datePart = try #require(date.parts.first as? SwifQLPartUnsafeValue)
        let timePart = try #require(time.parts.first as? SwifQLPartUnsafeValue)
        let dateTimePart = try #require(dateTime.parts.first as? SwifQLPartUnsafeValue)
        let intervalPart = try #require(interval.parts.first as? SwifQLPartUnsafeValue)

        #expect(date.parts.count == 1)
        #expect(time.parts.count == 1)
        #expect(dateTime.parts.count == 1)
        #expect(interval.parts.count == 1)
        #expect(datePart.unsafeValue as? PureDate == date)
        #expect(timePart.unsafeValue as? PureTime == time)
        #expect(dateTimePart.unsafeValue as? DateTime == dateTime)
        #expect(intervalPart.unsafeValue as? Interval == interval)
    }

    @Test("Mixed shared values retain one left-to-right bind stream")
    func mixedValuesPreserveBindingOrder() throws {
        let date = try sampleDate()
        let time = try sampleTime()
        let dateTime = try sampleDateTime()
        let interval = sampleInterval()
        let query = SwifQL.select("ordinary", 7, date, time, dateTime, interval)

        let expectedValues: [Any] = ["ordinary", 7, date, time, dateTime, interval]
        for dialect in [SQLDialect.psql, SQLDialect.duck, SQLDialect.mysql] {
            let prepared = query.prepare(dialect).splitted
            let expectedQuery = dialect == .mysql
                ? "SELECT ?, ?, ?, ?, ?, ?"
                : "SELECT $1, $2, $3, $4, $5, $6"
            #expect(prepared.query == expectedQuery)
            #expect(prepared.values.count == expectedValues.count)
            #expect(prepared.values[0] as? String == expectedValues[0] as? String)
            #expect(prepared.values[1] as? Int == expectedValues[1] as? Int)
            #expect(prepared.values[2] as? PureDate == expectedValues[2] as? PureDate)
            #expect(prepared.values[3] as? PureTime == expectedValues[3] as? PureTime)
            #expect(prepared.values[4] as? DateTime == expectedValues[4] as? DateTime)
            #expect(prepared.values[5] as? Interval == expectedValues[5] as? Interval)
        }
    }

    @Test("Optional values use the ordinary bound path and nil remains NULL")
    func optionalValuesPreserveExistingSemantics() throws {
        let date = try sampleDate()
        let someDate: PureDate? = date
        let noneDate: PureDate? = nil

        let some = SwifQL.select(someDate).prepare(.duck).splitted
        #expect(some.query == "SELECT $1")
        #expect(some.values.count == 1)
        #expect(some.values[0] as? PureDate == date)

        let none = SwifQL.select(noneDate).prepare(.duck).splitted
        #expect(none.query == "SELECT NULL")
        #expect(none.values.isEmpty)
    }

    @Test("Unsafe observation reports complete ordinary occurrences and indices")
    func observationReportsBoundOccurrences() throws {
        let date = try sampleDate()
        let time = try sampleTime()
        let dateTime = try sampleDateTime()
        let interval = sampleInterval()
        let observed = SwifQL.select(date, time, dateTime, interval)
            .prepareObservingUnsafeValues(.duck)

        guard case let .complete(occurrences) = observed.unsafeValueTrace else {
            Issue.record("Expected a complete unsafe value trace")
            return
        }

        #expect(occurrences.count == 4)
        #expect(occurrences.map(\.disposition) == [
            .bound(index: 0),
            .bound(index: 1),
            .bound(index: 2),
            .bound(index: 3)
        ])
        #expect(occurrences[0].value as? PureDate == date)
        #expect(occurrences[1].value as? PureTime == time)
        #expect(occurrences[2].value as? DateTime == dateTime)
        #expect(occurrences[3].value as? Interval == interval)
        #expect(observed.prepared.splitted.values.count == 4)
    }

    @Test("New values stay bound in ordinary SELECT and predicate contexts")
    func ordinaryContextsDoNotInlineNewValues() throws {
        let date = try sampleDate()
        let select = SwifQL.select(date).prepare(.duck).splitted
        #expect(select.query == "SELECT $1")
        #expect(select.values.count == 1)

        let predicate = SwifQL.where(Path.Column("event_date") == date)
            .prepare(.duck)
            .splitted
        #expect(predicate.query == #"WHERE "event_date" = $1"#)
        #expect(predicate.values.count == 1)
        #expect(predicate.values[0] as? PureDate == date)
    }

    @Test("Existing scalar binding remains unchanged alongside shared values")
    func existingScalarsRemainOrdinaryBinds() throws {
        let uuid = UUID(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")!
        let decimal = Decimal(string: "12.5")!
        let prepared = SwifQL.select("text", 42, uuid, decimal).prepare(.mysql).splitted

        #expect(prepared.query == "SELECT ?, ?, ?, ?")
        #expect(prepared.values[0] as? String == "text")
        #expect(prepared.values[1] as? Int == 42)
        #expect(prepared.values[2] as? UUID == uuid)
        #expect(prepared.values[3] as? Decimal == decimal)
    }
}
