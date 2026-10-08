@testable import SQL
import Testing

@Suite("Expression Frontier ARRAY Tests")
struct ExpressionFrontierArrayTests: SwifQLTests {
    private final class CountingSQLable: SQLable {
        private let value: any SQLable
        private(set) var reads = 0

        init(_ value: any SQLable) {
            self.value = value
        }

        var parts: [SQLPart] {
            reads += 1
            return value.parts
        }
    }

    @Test("SQLArray items use exact ARRAY syntax and preserve empty syntax")
    func exactItemsAndEmpty() {
        let concise = SQLArray.items(1, 2, Path.Column("score"))

        check(
            concise,
            .psql(#"ARRAY[1, 2, "score"]"#),
            .mysql("ARRAY[1, 2, score]"),
            .duck(#"ARRAY[1, 2, "score"]"#)
        )

        check(SQLArray.items {}, all: "ARRAY[]")
    }

    @Test("SQLArray items builder preserves optional branch and loop order")
    func builderControlFlow() {
        let includeMiddle = true
        let includeMissing = false
        let tail = [3, 4]

        let expression = SQLArray.items {
            1
            if includeMiddle {
                2
            }
            if includeMissing {
                99
            }
            for value in tail {
                value
            }
        }

        check(expression, all: "ARRAY[1, 2, 3, 4]")
    }

    @Test("SQLArray items preserve nested constructor boundaries")
    func nestedItems() {
        let nested = SQLArray.items(
            SQLArray.items(1, 2),
            SQLArray.items(3, 4)
        )
        let erased: any SQLable = nested
        let copied = SQLableParts(parts: nested.parts)

        check(nested, all: "ARRAY[ARRAY[1, 2], ARRAY[3, 4]]")
        #expect(erased.prepare(.psql).plain == nested.prepare(.psql).plain)
        #expect(copied.prepare(.psql).plain == nested.prepare(.psql).plain)
    }

    @Test("SQLArray subquery supports formed and builder statements")
    func subqueryForms() {
        let formed = SQL {
            Select { Path.Column("id") }
            From { Path.Table("orders") }
        }

        let direct = SQLArray.subquery(formed)
        let built = SQLArray.subquery {
            Select { Path.Column("id") }
            From { Path.Table("orders") }
        }

        for expression in [direct, built] {
            #expect(expression.prepare(.psql).plain == #"ARRAY(SELECT "id" FROM "orders")"#)
            #expect(expression.prepare(.duck).plain == #"ARRAY(SELECT "id" FROM "orders")"#)
            #expect(expression.prepare(.mysql).plain == "ARRAY(SELECT id FROM orders)")
        }
    }

    @Test("SQLArray items keep bind order and markers")
    func bindOrder() {
        let first = "O'Reilly"
        let second = "Привет 🦆"
        let expression = SQLArray.items(first, 7, second)

        let postgres = expression.prepare(.psql)
        #expect(postgres.plain == "ARRAY['O'Reilly', 7, 'Привет 🦆']")
        #expect(postgres.splitted.query == "ARRAY[$1, $2, $3]")
        #expect(postgres.splitted.values.count == 3)
        #expect(postgres.splitted.values[0] as? String == first)
        #expect(postgres.splitted.values[1] as? Int == 7)
        #expect(postgres.splitted.values[2] as? String == second)

        let duck = expression.prepare(.duck)
        #expect(duck.splitted.query == "ARRAY[$1, $2, $3]")
        #expect(duck.splitted.values.count == 3)

        let mysql = expression.prepare(.mysql)
        #expect(mysql.splitted.query == "ARRAY[?, ?, ?]")
        #expect(mysql.splitted.values.count == 3)
    }

    @Test("SQLArray composes inside SELECT and as a subscript base")
    func composition() {
        let select = Select {
            SQLArray.items(1, 2)
        }

        #expect(select.prepare(.psql).plain == "SELECT ARRAY[1, 2]")
        #expect(select.prepare(.duck).plain == "SELECT ARRAY[1, 2]")
        #expect(select.prepare(.mysql).plain == "SELECT ARRAY[1, 2]")

        let subscripted = SQLArray.items(1, 2)[1]
        #expect(subscripted.prepare(.psql).plain == "(ARRAY[1, 2])[1]")
        #expect(subscripted.prepare(.duck).plain == "ARRAY[1, 2][1]")
        #expect(subscripted.prepare(.mysql).plain == "ARRAY[1, 2][1]")
    }

    @Test("SQLArray does not remap Duck or MySQL element constructors")
    func noDialectRemapping() {
        let expression = SQLArray.items(1, 2, 3)

        #expect(expression.prepare(.duck).plain == "ARRAY[1, 2, 3]")
        #expect(expression.prepare(.mysql).plain == "ARRAY[1, 2, 3]")
        #expect(!expression.prepare(.duck).plain.contains("list_value"))
        #expect(!expression.prepare(.duck).plain.contains("array_value"))
    }

    @Test("SQLArray snapshots each supplied child exactly once")
    func singleEvaluation() {
        let first = CountingSQLable(1)
        let second = CountingSQLable(2)
        let builderValue = CountingSQLable(3)
        let statement = CountingSQLable(
            SQL {
                Select { Path.Column("id") }
            }
        )

        _ = SQLArray.items(first, second)
        _ = SQLArray.items {
            builderValue
        }
        _ = SQLArray.subquery(statement)

        #expect(first.reads == 1)
        #expect(second.reads == 1)
        #expect(builderValue.reads == 1)
        #expect(statement.reads == 1)
    }

    @Test("Legacy array surfaces remain unchanged")
    func legacyControls() {
        #expect(PostgresArray(1, 2).prepare(.psql).plain == "ARRAY[1, 2]")
        #expect(PgArray(3, 4).prepare(.psql).plain == "ARRAY[3, 4]")

        let swiftArray = [1, 2, 3]
        #expect(swiftArray.prepare(.duck).plain == "1, 2, 3")
        #expect(
            SQLableParts(parts: swiftArray).prepare(.duck).plain
                == "[1,2,3]"
        )
    }
}
