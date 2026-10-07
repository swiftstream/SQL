import Testing
@testable import SQL

private struct OperatorPreferenceFixture: Table {
    static var tableName: String { "operator_preference_fixture" }

    @Column("count")
    var count: Int64

    init() {}
}

@Suite("Operator overload preference")
struct OperatorOverloadPreferenceTests {
    private typealias Fixture = OperatorPreferenceFixture

    @Test("Ordinary Swift arithmetic and ordering retain stdlib result types")
    func ordinarySwiftPreference() {
        let integerLiteral = 5
        let _: Int = integerLiteral
        #expect(integerLiteral == 5)

        let floatingLiteral = 5.0
        let _: Double = floatingLiteral
        #expect(floatingLiteral == 5.0)

        let stringLiteral = ""
        let _: String = stringLiteral
        #expect(stringLiteral.isEmpty)

        let product = UInt64(7) * 10 + UInt64(3)
        let _: UInt64 = product
        #expect(product == 73)

        let quotient = UInt64(123) / 10
        let _: UInt64 = quotient
        #expect(quotient == 12)

        let sum = Int64(5) + 7
        let _: Int64 = sum
        #expect(sum == 12)

        let difference = Int64(5) - 2
        let _: Int64 = difference
        #expect(difference == 3)

        let multiplied = Int64(5) * 2
        let _: Int64 = multiplied
        #expect(multiplied == 10)

        let negative = Int64(-1) < 0
        let _: Bool = negative
        #expect(negative)

        let greater = Int64(2) > 1
        let _: Bool = greater
        #expect(greater)

        let greaterOrEqual = Int64(2) >= 2
        let _: Bool = greaterOrEqual
        #expect(greaterOrEqual)

        let lessOrEqual = Int64(2) <= 2
        let _: Bool = lessOrEqual
        #expect(lessOrEqual)

        let equal = Int64(1) == 1
        let _: Bool = equal
        #expect(equal)

        let concatenated = "a" + "b"
        let _: String = concatenated
        #expect(concatenated == "ab")
    }

    @Test("SQL arithmetic operators remain SQL expressions")
    func sqlArithmeticPreference() {
        let addition: any SQLable = \Fixture.$count + Int64(1)
        let subtraction: any SQLable = \Fixture.$count - Int64(1)
        let multiplication: any SQLable = \Fixture.$count * Int64(2)
        let division: any SQLable = \Fixture.$count / Int64(2)

        #expect(
            addition.prepare(.psql).plain
                == #""operator_preference_fixture"."count" + 1"#
        )
        #expect(
            subtraction.prepare(.psql).plain
                == #""operator_preference_fixture"."count" - 1"#
        )
        #expect(
            multiplication.prepare(.psql).plain
                == #""operator_preference_fixture"."count" * 2"#
        )
        #expect(
            division.prepare(.psql).plain
                == #""operator_preference_fixture"."count" / 2"#
        )

        let prepared = multiplication.prepare(.psql).splitted
        #expect(
            prepared.query
                == #""operator_preference_fixture"."count" * $1"#
        )
        #expect(prepared.values.map { String(describing: $0) } == ["2"])
    }

    @Test("SQL ordering operators remain SQL predicates")
    func sqlOrderingPreference() {
        let greater: any SQLable = \Fixture.$count > Int64(10)
        let less: any SQLable = \Fixture.$count < Int64(10)
        let greaterOrEqual: any SQLable = \Fixture.$count >= Int64(10)
        let lessOrEqual: any SQLable = \Fixture.$count <= Int64(10)

        #expect(
            greater.prepare(.psql).plain
                == #""operator_preference_fixture"."count" > 10"#
        )
        #expect(
            less.prepare(.psql).plain
                == #""operator_preference_fixture"."count" < 10"#
        )
        #expect(
            greaterOrEqual.prepare(.psql).plain
                == #""operator_preference_fixture"."count" >= 10"#
        )
        #expect(
            lessOrEqual.prepare(.psql).plain
                == #""operator_preference_fixture"."count" <= 10"#
        )

        #expect(
            greater.prepare(.mysql).plain
                == "operator_preference_fixture.count > 10"
        )
        #expect(
            greater.prepare(.duck).plain
                == #""operator_preference_fixture"."count" > 10"#
        )
    }

    @Test("SQL null equality and inequality remain SQL predicates")
    func sqlNullEqualityBoundary() {
        let count: any SQLable = \Fixture.$count
        let isNull: any SQLable = count == nil
        let isNotNull: any SQLable = count != nil
        let combined: any SQLable = isNull && isNotNull

        #expect(
            isNull.prepare(.psql).plain
                == #""operator_preference_fixture"."count" IS NULL"#
        )
        #expect(
            isNotNull.prepare(.psql).plain
                == #""operator_preference_fixture"."count" IS NOT NULL"#
        )
        #expect(
            combined.prepare(.psql).plain
                == #""operator_preference_fixture"."count" IS NULL AND "operator_preference_fixture"."count" IS NOT NULL"#
        )
    }
}
