@testable import SQL
import Foundation
import Testing

@Suite("Interval tests")
struct IntervalTests {
    @Test("Interval preserves structural basis components and mixed signs")
    func structuralValue() {
        let value = Interval(months: 2, days: -3, microseconds: 4)
        #expect(value.isFinite)
        #expect(!value.isZero)
        #expect(value.months == 2)
        #expect(value.days == -3)
        #expect(value.microseconds == 4)
        #expect(value == Interval(months: 2, days: -3, microseconds: 4))
        #expect(value != Interval(days: 21, microseconds: 4))
    }

    @Test("Interval factories preserve their exact units")
    func factories() throws {
        #expect(Interval.years(2)?.months == 24)
        #expect(Interval.months(3).months == 3)
        #expect(Interval.weeks(2)?.days == 14)
        #expect(Interval.days(3).days == 3)
        #expect(Interval.hours(2)?.microseconds == 7_200_000_000)
        #expect(Interval.minutes(3)?.microseconds == 180_000_000)
        #expect(Interval.seconds(4)?.microseconds == 4_000_000)
        #expect(Interval.milliseconds(5)?.microseconds == 5_000)
        #expect(Interval.microseconds(6).microseconds == 6)

        let oneYear = try #require(Interval.years(1))
        #expect(oneYear == Interval(months: 12))
    }

    @Test("Interval factory multiplication is checked")
    func factoryOverflow() {
        #expect(Interval.years(Int64.max) == nil)
        #expect(Interval.weeks(Int64.max) == nil)
        #expect(Interval.hours(Int64.max) == nil)
        #expect(Interval.minutes(Int64.max) == nil)
        #expect(Interval.seconds(Int64.max) == nil)
        #expect(Interval.milliseconds(Int64.max) == nil)
    }

    @Test("Interval zero and checked arithmetic preserve overflow failures")
    func arithmetic() {
        #expect(Interval.zero.isFinite)
        #expect(Interval.zero.isZero)
        #expect(!Interval(months: 1).isZero)
        #expect(Interval.zero.negated() == .zero)

        let sum = Interval(months: 2, days: -3, microseconds: 4).adding(
            Interval(months: -5, days: 7, microseconds: 8)
        )
        #expect(sum == Interval(months: -3, days: 4, microseconds: 12))
        #expect(Interval(months: 2).subtracting(Interval(months: 5)) == Interval(months: -3))

        #expect(Interval(months: Int64.max).adding(Interval(months: 1)) == nil)
        #expect(Interval(months: Int64.min).adding(Interval(months: -1)) == nil)
        #expect(Interval(months: Int64.min).negated() == nil)
        #expect(Interval(days: Int64.min).negated() == nil)
        #expect(Interval(microseconds: Int64.min).negated() == nil)
        #expect(Interval(months: Int64.min).subtracting(Interval(months: 1)) == nil)

        let bases: [(make: (Int64) -> Interval, component: (Interval) -> Int64?)] = [
            ({ Interval(months: $0) }, { $0.months }),
            ({ Interval(days: $0) }, { $0.days }),
            ({ Interval(microseconds: $0) }, { $0.microseconds })
        ]
        for base in bases {
            #expect(base.make(Int64.min).subtracting(base.make(Int64.min)) == .zero)
            #expect(base.component(base.make(-1).subtracting(base.make(Int64.min)) ?? .zero) == Int64.max)
            #expect(base.make(Int64.min).subtracting(base.make(1)) == nil)
            #expect(base.make(Int64.max).subtracting(base.make(-1)) == nil)
        }
    }

    @Test("Interval infinity arithmetic follows defined and undefined combinations")
    func infinities() {
        #expect(Interval.positiveInfinity.isFinite == false)
        #expect(Interval.negativeInfinity.isFinite == false)
        #expect(!Interval.positiveInfinity.isZero)
        #expect(Interval.positiveInfinity.months == nil)
        #expect(Interval.negativeInfinity.days == nil)

        #expect(Interval.positiveInfinity.negated() == .negativeInfinity)
        #expect(Interval.negativeInfinity.negated() == .positiveInfinity)
        #expect(Interval.positiveInfinity.adding(.positiveInfinity) == .positiveInfinity)
        #expect(Interval.negativeInfinity.adding(.negativeInfinity) == .negativeInfinity)
        #expect(Interval.zero.adding(.positiveInfinity) == .positiveInfinity)
        #expect(Interval.negativeInfinity.adding(Interval.zero) == .negativeInfinity)
        #expect(Interval.positiveInfinity.adding(.negativeInfinity) == nil)
        #expect(Interval.negativeInfinity.adding(.positiveInfinity) == nil)

        #expect(Interval.zero.subtracting(.positiveInfinity) == .negativeInfinity)
        #expect(Interval.zero.subtracting(.negativeInfinity) == .positiveInfinity)
        #expect(Interval.positiveInfinity.subtracting(Interval.zero) == .positiveInfinity)
        #expect(Interval.negativeInfinity.subtracting(Interval.zero) == .negativeInfinity)
        #expect(Interval.positiveInfinity.subtracting(.positiveInfinity) == nil)
        #expect(Interval.positiveInfinity.subtracting(.negativeInfinity) == .positiveInfinity)
        #expect(Interval.negativeInfinity.subtracting(.negativeInfinity) == nil)
        #expect(Interval.negativeInfinity.subtracting(.positiveInfinity) == .negativeInfinity)
    }

    @Test("Interval fixed-only Duration conversion is exact")
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func durationConversion() {
        let value = Interval(microseconds: -123_456)
        #expect(value.duration == Duration.microseconds(-123_456))
        #expect(Interval(days: 1).duration == nil)
        #expect(Interval(months: 1).duration == nil)
        #expect(Interval.positiveInfinity.duration == nil)
    }

    @Test("Interval Codable uses the exact tagged keyed representation")
    func codable() throws {
        let value = Interval(months: 2, days: -3, microseconds: 4)
        let encoded = try JSONEncoder().encode(value)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        #expect(Set(object.keys) == ["kind", "months", "days", "microseconds"])
        #expect(object["kind"] as? String == "finite")
        #expect(object["months"] as? Int == 2)
        #expect(object["days"] as? Int == -3)
        #expect(object["microseconds"] as? Int == 4)
        #expect(try JSONDecoder().decode(Interval.self, from: encoded) == value)

        for special in [Interval.positiveInfinity, Interval.negativeInfinity] {
            let data = try JSONEncoder().encode(special)
            let object = try #require(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            let expected = special == .positiveInfinity ? "positiveInfinity" : "negativeInfinity"
            #expect(object.keys.count == 1)
            #expect(object["kind"] as? String == expected)
            #expect(try JSONDecoder().decode(Interval.self, from: data) == special)
        }

        let missingBasis = Data(#"{"kind":"finite","months":0,"days":0}"#.utf8)
        let ambiguousInfinity = Data(#"{"kind":"positiveInfinity","months":0}"#.utf8)
        let unknownKind = Data(#"{"kind":"future"}"#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Interval.self, from: missingBasis)
        }
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Interval.self, from: ambiguousInfinity)
        }
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Interval.self, from: unknownKind)
        }
    }

    @Test("Interval has the required Sendable and Hashable value semantics")
    func sendableAndHashableCompileProof() {
        acceptsSendableAndHashable(Interval.zero)
    }
}

private func acceptsSendableAndHashable<Value: Sendable & Hashable>(_ value: Value) {
    _ = value
}
