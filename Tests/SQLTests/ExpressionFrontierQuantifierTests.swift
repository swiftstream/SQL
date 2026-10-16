@testable import SQL
import Testing

@Suite("Expression Frontier Quantifier Tests")
struct ExpressionFrontierQuantifierTests: SwifQLTests {
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

    @Test("Value quantifiers keep exact ANY ALL SOME spelling")
    func exactValueForms() {
        let score = DB.Column("score")

        let any = score == ANY(SQLArray.items(1, 2, 3))
        #expect(any.prepare(.psql).plain == #""score" = ANY (ARRAY[1, 2, 3])"#)

        let all = score > All(SQLArray.subquery {
            Select { DB.Column("threshold") }
            From { DB.Table("limits") }
        })
        #expect(
            all.prepare(.psql).plain
                == #""score" > ALL (ARRAY(SELECT "threshold" FROM "limits"))"#
        )

        let some = score == Some(SQLArray.items(2, 4))
        #expect(some.prepare(.psql).plain == #""score" = SOME (ARRAY[2, 4])"#)
    }

    @Test("Builder quantifiers are nested-statement grammar")
    func builderSubqueries() {
        let score = DB.Column("score")

        let any = score == ANY {
            Select { DB.Column("threshold") }
            From { DB.Table("limits") }
        }
        let all = score > All {
            Select { DB.Column("threshold") }
            From { DB.Table("limits") }
        }
        let some = score == Some {
            Select { DB.Column("threshold") }
            From { DB.Table("limits") }
        }

        check(
            any,
            .psql(#""score" = ANY (SELECT "threshold" FROM "limits")"#),
            .mysql("score = ANY (SELECT threshold FROM limits)"),
            .duck(#""score" = ANY (SELECT "threshold" FROM "limits")"#)
        )
        check(
            all,
            .psql(#""score" > ALL (SELECT "threshold" FROM "limits")"#),
            .mysql("score > ALL (SELECT threshold FROM limits)"),
            .duck(#""score" > ALL (SELECT "threshold" FROM "limits")"#)
        )
        check(
            some,
            .psql(#""score" = SOME (SELECT "threshold" FROM "limits")"#),
            .mysql("score = SOME (SELECT threshold FROM limits)"),
            .duck(#""score" = SOME (SELECT "threshold" FROM "limits")"#)
        )
    }

    @Test("Formed subquery operand preserves the same grammar")
    func formedSubquery() {
        let formed = SQL {
            Select { DB.Column("threshold") }
            From { DB.Table("limits") }
        }

        let expression = DB.Column("score") == ANY(formed)

        check(
            expression,
            .psql(#""score" = ANY (SELECT "threshold" FROM "limits")"#),
            .mysql("score = ANY (SELECT threshold FROM limits)"),
            .duck(#""score" = ANY (SELECT "threshold" FROM "limits")"#)
        )
    }

    @Test("Duck collection operands stay explicit")
    func duckCollectionOperands() {
        let score = DB.Column("score")

        let listAny = score == ANY(Fn.listValue(1, 2, 3))
        let arrayAll = score > All(Fn.arrayValue(1, 2, 3))
        let listSome = score == Some(Fn.listValue(1, 2, 3))

        #expect(
            listAny.prepare(.duck).plain
                == #""score" = ANY (list_value(1, 2, 3))"#
        )
        #expect(
            arrayAll.prepare(.duck).plain
                == #""score" > ALL (array_value(1, 2, 3))"#
        )
        #expect(
            listSome.prepare(.duck).plain
                == #""score" = SOME (list_value(1, 2, 3))"#
        )
    }

    @Test("SOME is not normalized to ANY")
    func someIdentity() {
        let expression = DB.Column("score") == Some {
            Select { DB.Column("threshold") }
        }

        let postgres = expression.prepare(.psql).plain
        #expect(postgres == #""score" = SOME (SELECT "threshold")"#)
        #expect(!postgres.contains("ANY"))
    }

    @Test("Bind order is lhs then quantified statement source order")
    func bindOrder() {
        let lhs = SQLableParts(parts: SQLPartUnsafeValue(10))
        let expression = lhs == ANY {
            Select { 20 }
            Where { DB.Column("value") == 30 }
        }

        let postgres = expression.prepare(.psql)
        #expect(postgres.splitted.query == #"$1 = ANY (SELECT $2 WHERE "value" = $3)"#)
        #expect(postgres.splitted.values.count == 3)
        #expect(postgres.splitted.values[0] as? Int == 10)
        #expect(postgres.splitted.values[1] as? Int == 20)
        #expect(postgres.splitted.values[2] as? Int == 30)

        let duck = expression.prepare(.duck)
        #expect(duck.splitted.query == #"$1 = ANY (SELECT $2 WHERE "value" = $3)"#)
        #expect(duck.splitted.values.count == 3)

        let mysql = expression.prepare(.mysql)
        #expect(mysql.splitted.query == "? = ANY (SELECT ? WHERE value = ?)")
        #expect(mysql.splitted.values.count == 3)
    }

    @Test("Row-valued quantified subquery composes structurally")
    func rowValuedSubquery() {
        let expression = Row(1, 2) == ANY {
            Select {
                1
                2
            }
        }

        #expect(
            expression.prepare(.psql).plain
                == "ROW(1, 2) = ANY (SELECT 1, 2)"
        )
        #expect(
            expression.prepare(.duck).plain
                == "ROW(1, 2) = ANY (SELECT 1, 2)"
        )
        #expect(
            expression.prepare(.mysql).plain
                == "ROW(1, 2) = ANY (SELECT 1, 2)"
        )
    }

    @Test("Value quantifiers snapshot operands exactly once")
    func singleEvaluation() {
        let anyOperand = CountingSQLable(SQLArray.items(1, 2))
        let allOperand = CountingSQLable(Fn.arrayValue(1, 2))
        let someOperand = CountingSQLable(Fn.listValue(1, 2))

        let any = ANY(anyOperand)
        let all = All(allOperand)
        let some = Some(someOperand)

        _ = any.prepare(.psql)
        _ = any.prepare(.duck)
        _ = all.prepare(.duck)
        _ = some.prepare(.duck)

        #expect(anyOperand.reads == 1)
        #expect(allOperand.reads == 1)
        #expect(someOperand.reads == 1)
    }

    @Test("Legacy instance any and all remain unchanged")
    func legacyCompatibility() {
        let base = DB.Column("value")
        let subquery = Select { DB.Column("id") }

        #expect(base.any.prepare(.psql).plain == #""value" ANY"#)
        #expect(
            base.any(subquery).prepare(.psql).plain
                == #""value" ANY(SELECT "id")"#
        )
        #expect(base.all.prepare(.psql).plain == #""value" ALL"#)
    }

    @Test("Swift Any remains fully usable beside SQL ANY")
    func swiftAnyCoexistence() {
        let erased: Any = 1
        let optional: Any? = "value"
        let values: [Any] = [1, "two"]
        let anyType: Any.Type = Any.self
        let cast = DB.Column("id") as Any

        #expect((erased as? Int) == 1)
        #expect((optional as? String) == "value")
        #expect(values.count == 2)
        _ = anyType
        _ = cast
    }
}
