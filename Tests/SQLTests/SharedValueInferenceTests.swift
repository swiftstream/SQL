import Foundation
import Testing
@testable import SQL

@Suite("Shared value inference")
struct SharedValueInferenceTests {
    @Test("Type.auto maps shared scalar and Optional scalar values")
    func typeAutoMatrix() {
        #expect(Type.auto(from: PureDate.self) == .date)
        #expect(Type.auto(from: Optional<PureDate>.self) == .date)
        #expect(Type.auto(from: PureTime.self) == .time)
        #expect(Type.auto(from: Optional<PureTime>.self) == .time)
        #expect(Type.auto(from: Date.self) == .timestamptz)
        #expect(Type.auto(from: Optional<Date>.self) == .timestamptz)
    }

    @Test("Column.autoType agrees and preserves optional flags")
    func columnAutoTypeMatrix() {
        let date = Column<PureDate>.autoType([])
        let optionalDate = Column<PureDate?>.autoType([])
        let time = Column<PureTime>.autoType([])
        let optionalTime = Column<PureTime?>.autoType([])
        let foundationDate = Column<Date>.autoType([])
        let optionalFoundationDate = Column<Date?>.autoType([])

        #expect(date.type == .date)
        #expect(!date.isOptional)
        #expect(optionalDate.type == .date)
        #expect(optionalDate.isOptional)
        #expect(time.type == .time)
        #expect(!time.isOptional)
        #expect(optionalTime.type == .time)
        #expect(optionalTime.isOptional)
        #expect(foundationDate.type == .timestamptz)
        #expect(!foundationDate.isOptional)
        #expect(optionalFoundationDate.type == .timestamptz)
        #expect(optionalFoundationDate.isOptional)
    }

    @Test("DateTime and Interval retain text fallback and explicit schemas")
    func unsupportedAutomaticMappingsRemainExplicit() {
        #expect(Type.auto(from: DateTime.self) == .text)
        #expect(Type.auto(from: Optional<DateTime>.self) == .text)
        #expect(Type.auto(from: Interval.self) == .text)
        #expect(Type.auto(from: Optional<Interval>.self) == .text)

        let dateTime = Column<DateTime>.autoType([])
        let optionalDateTime = Column<DateTime?>.autoType([])
        let interval = Column<Interval>.autoType([])
        let optionalInterval = Column<Interval?>.autoType([])
        #expect(dateTime.type == .text)
        #expect(dateTime.isOptional)
        #expect(optionalDateTime.type == .text)
        #expect(optionalDateTime.isOptional)
        #expect(interval.type == .text)
        #expect(interval.isOptional)
        #expect(optionalInterval.type == .text)
        #expect(optionalInterval.isOptional)

        let explicitDateTime = Column<DateTime>(name: "created_at", type: .timestamp)
        let explicitInterval = Column<Interval>(name: "elapsed", type: .interval)
        #expect(explicitDateTime.type == .timestamp)
        #expect(explicitInterval.type == .interval)
    }
}
