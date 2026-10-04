@testable import SQL
import Foundation
import Testing

@Suite("Duck dialect foundation")
struct DuckDBDialectTests: SwifQLTests {
    @Test("Duck identity and final SQLDialect.all membership stay explicit")
    func identity() {
        #expect(SQLDialect.duck.id == "duckdb")
        #expect(SQLDialect.all.map { $0.id } == ["psql", "mysql", "duckdb"])
    }

    @Test("Duck identifiers and strings escape correctly")
    func escaping() {
        check(
            SwifQL.select(Path.Schema("ana\"lytics").table("event\"s").column("id\"value")),
            .duck(#"SELECT "ana""lytics"."event""s"."id""value""#)
        )
        check(
            SwifQL.select(Path.Schema("данные").table("事件").column("名")),
            .duck(#"SELECT "данные"."事件"."名""#)
        )
        check(SwifQL.select("O'Reilly"), .duck("SELECT 'O''Reilly'"))
    }

    @Test("Duck bindings preserve value order")
    func bindings() {
        let prepared = SwifQL.select("alpha", 42).prepare(.duck)
        #expect(prepared.splitted.query == "SELECT $1, $2")
        #expect(prepared.splitted.values[0] as? String == "alpha")
        #expect(prepared.splitted.values[1] as? Int == 42)

        #expect(SwifQL.select([1, 2, 3]).prepare(.duck).plain == "SELECT 1, 2, 3")

        let values: [Int] = [1, 2, 3]
        let arrayExpression = SwifQLableParts(parts: values)
        let arrayPrepared = SwifQL.select(arrayExpression).prepare(.duck)
        #expect(arrayPrepared.plain == "SELECT [1,2,3]")
        #expect(arrayPrepared.splitted.query == "SELECT [$1,$2,$3]")
        #expect(arrayPrepared.splitted.values.map { $0 as? Int } == [1, 2, 3])
    }

    @Test("Duck Date uses deterministic UTC microseconds")
    func date() {
        let value = Date(timeIntervalSince1970: 1_577_934_245.123456)
        #expect(SwifQL.select(value).prepare(.duck).plain == "SELECT TIMESTAMPTZ '2020-01-02 03:04:05.123456+00:00'")
    }

    @Test("Duck hybrid operators require explicit Duck branches")
    func hybridOperators() {
        let legacy = SwifQLHybridOperator(SwifQLPartOperator("pg()"), SwifQLPartOperator("mysql()"))
        let explicit = SwifQLHybridOperator(
            SwifQLPartOperator("pg()"),
            SwifQLPartOperator("mysql()"),
            SwifQLPartOperator("duck()")
        )

        #expect(SwifQLHybridOperator.random.prepare(.psql).plain == "random()")
        #expect(SwifQLHybridOperator.random.prepare(.mysql).plain == "rand()")
        #expect(SwifQLHybridOperator.random.prepare(.duck).plain == "random()")
        #expect(legacy.prepare(.psql).plain == "pg()")
        #expect(legacy.prepare(.mysql).plain == "mysql()")
        #expect(legacy.prepare(.duck).plain == "<duck_hybrid_operator_requires_explicit_duck_branch>")
        #expect(explicit.prepare(.psql).plain == "pg()")
        #expect(explicit.prepare(.mysql).plain == "mysql()")
        #expect(explicit.prepare(.duck).plain == "duck()")
    }

    @Test("Hybrid representations are open, keyed, and value-semantic")
    func openHybridRepresentations() {
        let key = SwifQLHybridRepresentationKey(
            namespace: "vendor/sql 🦆",
            name: "fourth:dialect"
        )
        let equivalentKey = SwifQLHybridRepresentationKey(
            namespace: "vendor/sql 🦆",
            name: "fourth:dialect"
        )
        let differentKey = SwifQLHybridRepresentationKey(
            namespace: "vendor/sql 🦆",
            name: "fourth/other"
        )
        let hybrid = SwifQLHybridOperator(
            representations: [key: SwifQLPartOperator("fourth()")]
        )
        let copied = SwifQLHybridOperator(
            representations: [equivalentKey: SwifQLPartOperator("fourth()")]
        )
        let different = SwifQLHybridOperator(
            representations: [differentKey: SwifQLPartOperator("fourth()")]
        )

        #expect(hybrid.representation(for: key) == SwifQLPartOperator("fourth()"))
        #expect(hybrid == copied)
        #expect(hybrid != different)
        #expect(hybrid.representations.count == 1)
    }

    @Test("Duck fromBase64 uses exact SQL identity and normal binds")
    func fromBase64() {
        let query = SwifQL.select(Fn.fromBase64("O'Reilly"), Fn.fromBase64("данные 🦆"))
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == "SELECT from_base64('O''Reilly'), from_base64('данные 🦆')")
        #expect(prepared.splitted.query == "SELECT from_base64($1), from_base64($2)")
        #expect(prepared.splitted.values.map { $0 as? String } == ["O'Reilly", "данные 🦆"])

        let psql = query.prepare(.psql)
        #expect(psql.plain == "SELECT from_base64('O'Reilly'), from_base64('данные 🦆')")
        #expect(psql.splitted.query == "SELECT from_base64($1), from_base64($2)")
        #expect(psql.splitted.values.map { $0 as? String } == ["O'Reilly", "данные 🦆"])

        let mysql = query.prepare(.mysql)
        #expect(mysql.plain == "SELECT FROM_BASE64('O'Reilly'), FROM_BASE64('данные 🦆')")
        #expect(mysql.splitted.query == "SELECT FROM_BASE64(?), FROM_BASE64(?)")
        #expect(mysql.splitted.values.map { $0 as? String } == ["O'Reilly", "данные 🦆"])
    }
}
