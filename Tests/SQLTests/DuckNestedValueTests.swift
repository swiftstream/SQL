@testable import SQL
import Foundation
import Testing

@Suite("Duck nested value tests")
struct DuckNestedValueTests: SwifQLTests {
    @Test("LIST ARRAY and MAP use their exact Duck SQL names")
    func exactFunctionNames() {
        let query = SwifQL.select(
            Fn.listValue(1, 2, 3),
            Fn.arrayValue(1, 2, 3),
            Fn.map(
                Fn.listValue("one", "two"),
                Fn.listValue(1, 2)
            )
        )

        check(
            query,
            .duck("SELECT list_value(1, 2, 3), array_value(1, 2, 3), map(list_value('one', 'two'), list_value(1, 2))")
        )
    }

    @Test("Prepared nested values preserve Duck bind markers and left-to-right order")
    func preparedValues() {
        let firstText = "O'Reilly"
        let secondText = "Привет 🦆"
        let query = SwifQL.select(
            Fn.listValue(1, 2, 3),
            Fn.listValue(firstText, secondText),
            Fn.arrayValue(4, 5, 6),
            Fn.map(
                Fn.listValue("one", "two"),
                Fn.listValue(7, 8)
            )
        )

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == "SELECT list_value(1, 2, 3), list_value('O''Reilly', 'Привет 🦆'), array_value(4, 5, 6), map(list_value('one', 'two'), list_value(7, 8))")
        #expect(prepared.splitted.query == "SELECT list_value($1, $2, $3), list_value($4, $5), array_value($6, $7, $8), map(list_value($9, $10), list_value($11, $12))")

        let values = prepared.splitted.values
        #expect(values.count == 12)
        #expect(values[0] as? Int == 1)
        #expect(values[1] as? Int == 2)
        #expect(values[2] as? Int == 3)
        #expect(values[3] as? String == firstText)
        #expect(values[4] as? String == secondText)
        #expect(values[5] as? Int == 4)
        #expect(values[6] as? Int == 5)
        #expect(values[7] as? Int == 6)
        #expect(values[8] as? String == "one")
        #expect(values[9] as? String == "two")
        #expect(values[10] as? Int == 7)
        #expect(values[11] as? Int == 8)
    }

    @Test("Nested LIST expressions remain recursively composable")
    func nestedList() {
        let nested = Fn.listValue(
            Fn.listValue(1, 2),
            Fn.listValue(3, 4)
        )
        let copied: SwifQLable = nested
        let stored = SwifQLableParts(parts: nested.parts)

        #expect(nested.prepare(.duck).plain == "list_value(list_value(1, 2), list_value(3, 4))")
        #expect(copied.prepare(.duck).plain == nested.prepare(.duck).plain)
        #expect(stored.prepare(.duck).plain == nested.prepare(.duck).plain)
        #expect(nested.prepare(.duck).splitted.query == "list_value(list_value($1, $2), list_value($3, $4))")
    }

    @Test("LIST and ARRAY keep distinct exact SQL value constructors")
    func listAndArrayRemainDistinct() {
        let values: [SwifQLable] = [1, 2, 3]

        #expect(Fn.listValue(values).prepare(.duck).plain == "list_value(1, 2, 3)")
        #expect(Fn.arrayValue(values).prepare(.duck).plain == "array_value(1, 2, 3)")
        #expect(Fn.listValue().prepare(.duck).plain == "list_value()")
    }

    @Test("PostgreSQL and MySQL remain unclaimed without semantic remapping")
    func unclaimedOtherDialects() {
        let expression = Fn.listValue(1, 2, 3)

        #expect(expression.prepare(.psql).plain == "list_value(1, 2, 3)")
        #expect(expression.prepare(.mysql).plain == "list_value(1, 2, 3)")
    }

    @Test("Historical Swift array value composition remains unchanged")
    func historicalArrayValues() {
        let values: [Int] = [1, 2, 3]
        let query = SwifQL.select(SwifQLableParts(parts: values))
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == "SELECT [1,2,3]")
        #expect(prepared.splitted.query == "SELECT [$1,$2,$3]")
        #expect(prepared.splitted.values.map { $0 as? Int } == [1, 2, 3])
    }
}
