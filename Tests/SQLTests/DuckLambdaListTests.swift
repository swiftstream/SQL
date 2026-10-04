@testable import SQL
import Testing

private final class ArrowLambdaDialect: SQLDialect {
    override func bindKey(_ i: Int) -> String { "$\(i)" }
    override func column(_ value: String) -> String {
        SQLDialect.duck.column(value)
    }

    override func lambda(_ lambda: SwifQLPartLambda) -> [SwifQLPart] {
        guard let parameter = lambda.parameters.first,
              lambda.parameters.count == 1 else {
            return super.lambda(lambda)
        }

        var parts: [SwifQLPart] = parameter.parts
        parts.append(o: .space, .custom("->"), .space)
        parts.append(contentsOf: lambda.body)
        return parts
    }
}

@Suite("Duck lambda and LIST tests")
struct DuckLambdaListTests: SwifQLTests {
    @Test("One-parameter lambdas use canonical future-safe syntax")
    func oneParameterLambda() {
        let lambda = SQLLambda("x") { x in x + 1 }
        let query = Fn.listTransform(Fn.listValue(1, 2, 3), lambda)

        #expect(
            query.prepare(.duck).plain ==
                #"list_transform(list_value(1, 2, 3), lambda "x" : "x" + 1)"#
        )
        #expect(!query.prepare(.duck).plain.contains("->"))
        #expect(
            query.prepare(.duck).splitted.query ==
                #"list_transform(list_value($1, $2, $3), lambda "x" : "x" + $4)"#
        )
        #expect(query.prepare(.duck).splitted.values.map { $0 as? Int } == [1, 2, 3, 1])
    }

    @Test("Two-parameter lambdas preserve Duck's one-based index")
    func twoParameterLambda() {
        let lambda = SQLLambda("x", "i") { x, i in x + i }
        let query = Fn.listTransform(Fn.listValue(10, 20, 30), lambda)

        #expect(
            query.prepare(.duck).plain ==
                #"list_transform(list_value(10, 20, 30), lambda "x", "i" : "x" + "i")"#
        )
        #expect(lambda.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Lambda parameters use structural safe identifier rendering")
    func safeParameterIdentifiers() {
        let reserved = SQLLambda("select") { parameter in parameter + 1 }
        let unicode = SQLLambda("имя") { parameter in parameter }
        let embeddedQuote = SQLLambda("a\"b") { parameter in parameter }

        #expect(reserved.prepare(.duck).plain == #"lambda "select" : "select" + 1"#)
        #expect(unicode.prepare(.duck).plain == #"lambda "имя" : "имя""#)
        #expect(embeddedQuote.prepare(.duck).plain == #"lambda "a""b" : "a""b""#)
    }

    @Test("LIST helpers keep exact function identities and signatures")
    func exactListHelpers() {
        let values = Fn.listValue(1, 2, 3)
        let transform = Fn.listTransform(values, SQLLambda("x") { x in x + 1 })
        let filter = Fn.listFilter(values, SQLLambda("x") { x in x == 1 })
        let reduce = Fn.listReduce(values, SQLLambda("acc", "x") { acc, x in acc + x })
        let initialReduce = Fn.listReduce(
            values,
            SQLLambda("acc", "x") { acc, x in acc + x },
            10
        )

        #expect(transform.prepare(.duck).plain == #"list_transform(list_value(1, 2, 3), lambda "x" : "x" + 1)"#)
        #expect(filter.prepare(.duck).plain == #"list_filter(list_value(1, 2, 3), lambda "x" : "x" = 1)"#)
        #expect(reduce.prepare(.duck).plain == #"list_reduce(list_value(1, 2, 3), lambda "acc", "x" : "acc" + "x")"#)
        #expect(initialReduce.prepare(.duck).plain == #"list_reduce(list_value(1, 2, 3), lambda "acc", "x" : "acc" + "x", 10)"#)
    }

    @Test("Lambda body binds follow list-expression binds")
    func preparedIntegerBinds() {
        let query = Fn.listTransform(
            Fn.listValue(1, 2),
            SQLLambda("x") { x in x + 10 }
        )
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == #"list_transform(list_value(1, 2), lambda "x" : "x" + 10)"#)
        #expect(prepared.splitted.query == #"list_transform(list_value($1, $2), lambda "x" : "x" + $3)"#)
        #expect(prepared.splitted.values.map { $0 as? Int } == [1, 2, 10])
    }

    @Test("Text binds preserve apostrophes and Unicode inside lambda bodies")
    func preparedTextBinds() {
        let first = "O'Reilly"
        let second = "Привет 🦆"
        let query = Fn.listFilter(
            Fn.listValue(first, second),
            SQLLambda("x") { x in x == second }
        )
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == #"list_filter(list_value('O''Reilly', 'Привет 🦆'), lambda "x" : "x" = 'Привет 🦆')"#)
        #expect(prepared.splitted.query == #"list_filter(list_value($1, $2), lambda "x" : "x" = $3)"#)
        #expect(prepared.splitted.values.count == 3)
        #expect(prepared.splitted.values[0] as? String == first)
        #expect(prepared.splitted.values[1] as? String == second)
        #expect(prepared.splitted.values[2] as? String == second)
    }

    @Test("Outer columns compose through ordinary path expressions")
    func outerColumnCapture() {
        let table = Path.Table("lambda_capture")
        let items = table.column("items")
        let delta = table.column("delta")
        let query = SwifQL
            .select(Fn.listTransform(items, SQLLambda("x") { x in x + delta }))
            .from(table)

        #expect(
            query.prepare(.duck).plain ==
                #"SELECT list_transform("lambda_capture"."items", lambda "x" : "x" + "lambda_capture"."delta") FROM "lambda_capture""#
        )
    }

    @Test("Nested lambdas preserve distinct names and outer capture")
    func nestedLambda() {
        let nested = SQLLambda("row_value") { rowValue in
            Fn.listTransform(
                rowValue,
                SQLLambda("item") { item in item + rowValue[1] }
            )
        }
        let query = Fn.listTransform(
            Fn.listValue(Fn.listValue(1, 2), Fn.listValue(3, 4)),
            nested
        )

        #expect(
            query.prepare(.duck).plain ==
                #"list_transform(list_value(list_value(1, 2), list_value(3, 4)), lambda "row_value" : list_transform("row_value", lambda "item" : "item" + "row_value"[1]))"#
        )

        let prepared = SQLLambda("row_value") { rowValue in
            Fn.listTransform(
                rowValue,
                SQLLambda("item") { item in item + 1 }
            )
        }.prepare(.duck)
        #expect(
            prepared.splitted.query ==
                #"lambda "row_value" : list_transform("row_value", lambda "item" : "item" + $1)"#
        )
        #expect(prepared.splitted.values.map { $0 as? Int } == [1])
    }

    @Test("Copied and stored lambdas preserve composition")
    func copiedAndStoredLambda() {
        let lambda = SQLLambda("x") { x in x + 1 }
        let copied: SwifQLable = lambda
        let stored = SwifQLableParts(parts: lambda.parts)
        let original = Fn.listTransform(Fn.listValue(1, 2), lambda).prepare(.duck).plain

        #expect(copied.prepare(.duck).plain == #"lambda "x" : "x" + 1"#)
        #expect(stored.prepare(.duck).plain == copied.prepare(.duck).plain)
        #expect(Fn.listTransform(Fn.listValue(1, 2), copied).prepare(.duck).plain == original)
        #expect(Fn.listTransform(Fn.listValue(1, 2), stored).prepare(.duck).plain == original)
        #expect(lambda.parts.count == 1)
        #expect(lambda.parts.first is SwifQLPartLambda)

        var conditional: SwifQLable = lambda
        if true {
            conditional = Fn.listTransform(Fn.listValue(1), conditional)
        }
        #expect(
            conditional.prepare(.duck).plain ==
                #"list_transform(list_value(1), lambda "x" : "x" + 1)"#
        )
    }

    @Test("Lambda dialect boundary preserves body binds and legacy defaults")
    func lambdaDialectBoundary() {
        let lambda = SQLLambda("select") { parameter in parameter + 7 }
        let arrow = lambda.prepare(ArrowLambdaDialect())
        #expect(arrow.plain == #""select" -> "select" + 7"#)
        #expect(arrow.splitted.query == #""select" -> "select" + $1"#)
        #expect(arrow.splitted.values.map { $0 as? Int } == [7])

        let legacy = lambda.prepare(SQLDialect())
        #expect(legacy.plain == "lambda select : select + 7")
        #expect(legacy.splitted.values.map { $0 as? Int } == [7])
    }

    @Test("PostgreSQL and MySQL render exact tokens without a support claim")
    func mechanicalOtherDialects() {
        let query = Fn.listTransform(Fn.listValue(1, 2), SQLLambda("x") { x in x + 1 })

        #expect(query.prepare(.psql).plain == #"list_transform(list_value(1, 2), lambda "x" : "x" + 1)"#)
        #expect(query.prepare(.mysql).plain == "list_transform(list_value(1, 2), lambda x : x + 1)")
    }
}
