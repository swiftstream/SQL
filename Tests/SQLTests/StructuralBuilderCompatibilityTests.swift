import Foundation
import Testing
@testable import SQL

private final class StructuralBuilderScopeDialect: SQLDialect {
    private let observedScope: SwifQLRenderScope

    init(observedScope: SwifQLRenderScope) {
        self.observedScope = observedScope
        super.init()
    }

    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "plain"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        context.contains(observedScope) ? "scoped" : "plain"
    }
}

@Suite("Structural builder compatibility")
struct StructuralBuilderCompatibilityTests: SwifQLTests {
    private let outerOwner = SwifQLClauseOwner(namespace: "example", name: "outer")
    private let nestedOwner = SwifQLClauseOwner(namespace: "example", name: "nested")

    private func root(of query: SwifQLable) -> SwifQLStructuralFramePart {
        query.parts.first as! SwifQLStructuralFramePart
    }

    private func groupByPart(in frame: SwifQLStructuralFramePart) -> SwifQLGroupByPart? {
        frame.children.compactMap { $0 as? SwifQLGroupByPart }.first
    }

    private func orderByPart(in frame: SwifQLStructuralFramePart) -> SwifQLOrderByPart? {
        frame.children.compactMap { $0 as? SwifQLOrderByPart }.first
    }

    private func ownedStatement(_ owner: SwifQLClauseOwner) -> SwifQLable {
        SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner, .orderBy: owner],
            children: [SwifQLPartOperator.custom("SELECT")]
        ))
    }

    @Test("Nested statement frames remain opaque inside an owned outer frame")
    func nestedStatementOwnership() {
        let nested = ownedStatement(nestedOwner).groupBy("nested")
        let outer = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: outerOwner, .orderBy: outerOwner],
            children: nested.parts
        ))
        let query = outer.groupBy("outer").orderBy(.asc("outerOrder"))
        let outerFrame = root(of: query)
        let nestedFrame = outerFrame.children.compactMap { $0 as? SwifQLStructuralFramePart }.first!

        #expect(groupByPart(in: outerFrame)?.owner == outerOwner)
        #expect(orderByPart(in: outerFrame)?.owner == outerOwner)
        #expect(groupByPart(in: nestedFrame)?.owner == nestedOwner)
    }

    @Test("An owned nested frame does not claim an ordinary outer clause")
    func nestedOwnerDoesNotLeakOutward() {
        let nested = ownedStatement(nestedOwner).orderBy(.desc("nestedOrder"))
        let outer = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            children: nested.parts
        ))
        let query = outer.groupBy("outer")
        let outerFrame = root(of: query)
        let nestedFrame = outerFrame.children.compactMap { $0 as? SwifQLStructuralFramePart }.first!

        #expect(groupByPart(in: outerFrame)?.owner == nil)
        #expect(orderByPart(in: nestedFrame)?.owner == nestedOwner)
    }

    @Test("Helper, variable, conditional, and copied assembly preserve structural parts")
    func incrementalCopiedAssembly() {
        func appendHelper(_ query: SwifQLable) -> SwifQLable {
            let fragmentParts: [SwifQLPart] = [
                SwifQLPartOperator.space,
                SwifQLPartOperator.custom("HELPER_TAIL")
            ]
            return query.structurallyAppending(SwifQLableParts(parts: fragmentParts))
        }

        let table = Path.Table("events")
        var query: SwifQLable = SwifQL.select(table.column("id")).from(table)
        if true {
            query = query.groupBy(table.column("id"))
        }
        query = SwifQLableParts(parts: query.parts)
        query = appendHelper(query)

        let frame = root(of: query)
        #expect(groupByPart(in: frame)?.owner == nil)
        #expect(frame.children.contains { ($0 as? SwifQLPartOperator)?._value == "HELPER_TAIL" })
        #expect(query.prepare(.psql).plain == #"SELECT "events"."id" FROM "events" GROUP BY "events"."id" HELPER_TAIL"#)
    }

    @Test("WITH bodies are nested statement frames and keep outer clauses separate")
    func withIsolation() {
        let table = Path.Table("events")
        let body = ownedStatement(nestedOwner).groupBy(table.column("kind"))
        let outer = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: outerOwner],
            children: []
        ))
        let query = outer
            .with(.init(Path.Table("grouped"), body))
            .groupBy(table.column("kind"))

        let outerFrame = root(of: query)
        let nestedFrames = outerFrame.children.compactMap { $0 as? SwifQLStructuralFramePart }
        #expect(groupByPart(in: outerFrame)?.owner == outerOwner)
        #expect(nestedFrames.contains { groupByPart(in: $0)?.owner == nestedOwner })

        let ordinary = SwifQL
            .with(.init(Path.Table("recent"), SwifQL.select(table.column("id")).from(table)))
            .select(Path.Table("recent").column("id"))
            .from(Path.Table("recent"))
        check(
            ordinary,
            .psql(#"WITH "recent" as (SELECT "events"."id" FROM "events") SELECT "recent"."id" FROM "recent""#),
            .mysql("WITH recent as (SELECT events.id FROM events) SELECT recent.id FROM recent")
        )
    }

    @Test("UNION and UNION ALL use a set-result root and final ORDER BY")
    func unionSetResultOwnership() {
        let leftTable = Path.Table("left_table")
        let rightTable = Path.Table("right_table")
        let left = SwifQL.select(leftTable.column("id")).from(leftTable)
        let right = SwifQL.select(rightTable.column("id")).from(rightTable)

        let union = Union([left, right]).orderBy(.asc(leftTable.column("id")))
        let unionFrame = root(of: union)
        let operands = unionFrame.children.compactMap { $0 as? SwifQLStructuralFramePart }

        #expect(unionFrame.region == .setResult)
        #expect(operands.count == 2)
        #expect(orderByPart(in: unionFrame)?.owner == nil)
        #expect(orderByPart(in: operands[1]) == nil)
        check(
            union,
            .psql(#"(SELECT "left_table"."id" FROM "left_table") UNION (SELECT "right_table"."id" FROM "right_table") ORDER BY "left_table"."id" ASC"#),
            .mysql("(SELECT left_table.id FROM left_table) UNION (SELECT right_table.id FROM right_table) ORDER BY left_table.id ASC")
        )

        let unionAll = Union(all: left, right)
        check(
            unionAll,
            .psql(#"(SELECT "left_table"."id" FROM "left_table") UNION ALL (SELECT "right_table"."id" FROM "right_table")"#),
            .mysql("(SELECT left_table.id FROM left_table) UNION ALL (SELECT right_table.id FROM right_table)")
        )

        let methodUnion = left.union(right).orderBy(.desc(leftTable.column("id")))
        #expect(root(of: methodUnion).region == .setResult)
    }

    @Test("Nested SELECT, set-result, and builder outputs preserve exact SQL and bind order")
    func nestedAndBuilderCompatibility() {
        let users = Path.Table("users")
        let id = users.column("id")
        let age = users.column("age")
        let nested = SwifQL
            .select(id)
            .from(|SwifQL.select(id).from(users).where(age > 18)|)
        check(
            nested,
            .psql(#"SELECT "users"."id" FROM (SELECT "users"."id" FROM "users" WHERE "users"."age" > 18)"#),
            .mysql("SELECT users.id FROM (SELECT users.id FROM users WHERE users.age > 18)")
        )

        let builder = SwifQLSelectBuilder()
            .select(users.*)
            .from(users)
            .where(age > 18)
            .groupBy(users.column("name"))
            .having(Fn.count(users.column("score")) > 1)
            .orderBy(.asc(users.column("name")))
            .limit(20)
            .offset(2)
        check(
            builder.build(),
            .psql(
                #"SELECT "users".* FROM "users" WHERE "users"."age" > 18 GROUP BY "users"."name" HAVING count("users"."score") > 1 ORDER BY "users"."name" ASC LIMIT 20 OFFSET 2"#,
                #"SELECT "users".* FROM "users" WHERE "users"."age" > $1 GROUP BY "users"."name" HAVING count("users"."score") > $2 ORDER BY "users"."name" ASC LIMIT $3 OFFSET $4"#
            ),
            .mysql(
                "SELECT users.* FROM users WHERE users.age > 18 GROUP BY users.name HAVING count(users.score) > 1 ORDER BY users.name ASC LIMIT 20 OFFSET 2",
                "SELECT users.* FROM users WHERE users.age > ? GROUP BY users.name HAVING count(users.score) > ? ORDER BY users.name ASC LIMIT ? OFFSET ?"
            )
        )
        #expect(builder.build().prepare(.psql).splitted.values.map { String(describing: $0) } == ["18", "1", "20", "2"])
    }

    @Test("Historical raw tilde composition retains Task 01 PostgreSQL/MySQL bytes")
    func historicalTildeCompositionCompatibility() {
        let users = Path.Table("users")
        let age = users.column("age")
        let tildeParts: [SwifQLable] = [
            SwifQL, Op.select, Op.space, users.*,
            Op.space, Op.from, Op.space, users,
            Op.space, Op.where, Op.space, (age > 18)
        ]
        let tilde = tildeParts.dropFirst().reduce(tildeParts[0]) { $0 ~ $1 }

        let psql = tilde.prepare(.psql)
        #expect(psql.plain == #"SELECT "users".*  FROM "users" WHERE "users"."age" > 18"#)
        #expect(psql.splitted.query == #"SELECT "users".*  FROM "users" WHERE "users"."age" > $1"#)
        #expect(psql.splitted.values.map { String(describing: $0) } == ["18"])

        let mysql = tilde.prepare(.mysql)
        #expect(mysql.plain == "SELECT users.*  FROM users WHERE users.age > 18")
        #expect(mysql.splitted.query == "SELECT users.*  FROM users WHERE users.age > ?")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["18"])
    }

    @Test("Raw tilde with an unframed SwifQLable preserves explicit spaces and owner")
    func rawTildeSwifQLableFragmentPreservesSpaces() {
        let owner = SwifQLClauseOwner(namespace: "example", name: "raw")
        let lhs: SwifQLable = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner],
            children: [
                SwifQLPartOperator.custom("BASE"),
                SwifQLPartOperator.space
            ]
        ))
        let rhsParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("TAIL")
        ]
        let rhs: SwifQLable = SwifQLableParts(parts: rhsParts)

        let query = lhs ~ rhs
        let frame = root(of: query)
        #expect(query.parts.count == 1)
        #expect(frame.owner(for: .groupBy) == owner)
        #expect(frame.children.filter {
            ($0 as? SwifQLPartOperator)?._value == " "
        }.count == 2)
        #expect(query.prepare(.psql).plain == "BASE  TAIL")
    }

    @Test("Raw tilde with a SwifQLPartOperator preserves an explicit second space")
    func rawTildeOperatorFragmentPreservesSpaces() {
        let lhs: SwifQLable = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartOperator.custom("BASE"),
                SwifQLPartOperator.space
            ]
        ))

        let query = lhs ~ SwifQLPartOperator.space
        let frame = root(of: query)
        #expect(query.parts.count == 1)
        #expect(frame.children.filter {
            ($0 as? SwifQLPartOperator)?._value == " "
        }.count == 2)
        #expect(query.prepare(.psql).plain == "BASE  ")
    }

    @Test("Static raw uses supplied trusted text across dialects without binds")
    func staticRawUsesSuppliedTrustedText() {
        let staticRaw = SwifQLableParts.raw("TAIL")
        let stringRaw = "TAIL".raw
        let base: SwifQLable = SwifQLableParts(parts: SwifQLPartOperator.custom("BASE"))
        let composed = base ~ staticRaw

        for dialect in [SQLDialect.psql, SQLDialect.mysql, SQLDialect.duck] {
            let staticPrepared = staticRaw.prepare(dialect)
            #expect(staticPrepared.plain == " TAIL")
            #expect(staticPrepared.splitted.query == " TAIL")
            #expect(staticPrepared.splitted.values.isEmpty)

            let stringPrepared = stringRaw.prepare(dialect)
            #expect(stringPrepared.plain == "TAIL")
            #expect(stringPrepared.splitted.query == "TAIL")
            #expect(stringPrepared.splitted.values.isEmpty)

            let composedPrepared = composed.prepare(dialect)
            #expect(composedPrepared.plain == "BASE TAIL")
            #expect(composedPrepared.splitted.query == "BASE TAIL")
            #expect(composedPrepared.splitted.values.isEmpty)
        }
    }

    @Test("structurallyAppending retains normalized single-separator behavior")
    func structurallyAppendingRemainsNormalized() {
        let lhs: SwifQLable = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartOperator.custom("BASE"),
                SwifQLPartOperator.space
            ]
        ))
        let fragmentParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("TAIL")
        ]
        let fragment: SwifQLable = SwifQLableParts(parts: fragmentParts)

        let query = lhs.structurallyAppending(fragment)
        let frame = root(of: query)
        #expect(query.parts.count == 1)
        #expect(frame.children.filter {
            ($0 as? SwifQLPartOperator)?._value == " "
        }.count == 1)
        #expect(query.prepare(.psql).plain == "BASE TAIL")
    }

    @Test("Expression parentheses stay syntax-only and raw tilde semantics remain distinct")
    func parenthesesAndTilde() {
        let expression = |(Path.Table("events").column("year") + 1)|
        #expect(expression.parts.first is SwifQLStructuralFramePart == false)

        let continuationParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("TAIL")
        ]
        let continued = SwifQL.select(1) ~ SwifQLableParts(parts: continuationParts)
        #expect(continued.parts.count == 1)
        #expect(continued.prepare(.psql).plain == "SELECT 1 TAIL")

        let independent = SwifQL.select(1) ~ SwifQL.select(2)
        #expect(independent.parts.count == 2)
        #expect(independent.parts.allSatisfy { $0 is SwifQLStructuralFramePart })

        let flatParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("RIGHT")
        ]
        let flat = SwifQLableParts(parts: SwifQLPartOperator.custom("LEFT")) ~ SwifQLableParts(parts: flatParts)
        #expect(flat.prepare(.psql).plain == "LEFT RIGHT")
    }

    @Test("Nested statement frames reset scopes and preserve depth-first bindings")
    func scopeAndBindingIsolation() {
        let scope = SwifQLRenderScope(namespace: "example", name: "outer")
        let outerExpression = Path.Table("outer").column("value").scoped(scope)
        let nestedFrame = SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartUnsafeValue("insideNested"),
                SwifQLPartOperator.space,
                SwifQLPartUnsafeValue("nestedWhere")
            ]
        )
        let rootFrame = SwifQLStructuralFramePart(
            region: .statement,
            children: [
                outerExpression.parts[0],
                SwifQLPartOperator.space,
                nestedFrame,
                SwifQLPartOperator.space,
                SwifQLPartUnsafeValue("after")
            ]
        )
        let query = SwifQLableParts(parts: rootFrame)
        let dialect = StructuralBuilderScopeDialect(observedScope: scope)
        let prepared = query.prepare(dialect)

        #expect(prepared.plain == "scoped 'insideNested' 'nestedWhere' 'after'")
        #expect(prepared.splitted.values.map { String(describing: $0) } == [
            "insideNested", "nestedWhere", "after"
        ])
    }

    @Test("Stored MATCH_CONDITION and ON roles survive select-builder materialization")
    func storedMatchConditionOnBuilderComposition() {
        let trades = Path.Table("trades")
        let prices = Path.Table("prices")
        let base = SwifQL.select(trades.column("id")).from(trades)
        let temporal = trades.column("event_time") >= 100
        let equality = trades.column("symbol") == "A"
        let storedJoin = SwifQLJoinBuilder(
            .asOf,
            prices,
            matchCondition: temporal,
            on: equality
        )

        let built = SwifQLSelectBuilder()
            .select(trades.column("id"))
            .from(trades)
            .join(storedJoin)
            .build()
        let direct = base.join(
            .asOf,
            prices,
            matchCondition: temporal,
            on: equality
        )

        let psql = built.prepare(.psql)
        let directPsql = direct.prepare(.psql)
        #expect(psql.plain == directPsql.plain)
        #expect(
            psql.plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= 100) ON "trades"."symbol" = 'A'"#
        )
        #expect(psql.splitted.query == directPsql.splitted.query)
        #expect(
            psql.splitted.query ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= $1) ON "trades"."symbol" = $2"#
        )
        #expect(psql.splitted.values.map { String(describing: $0) } == ["100", "A"])
        #expect(directPsql.splitted.values.map { String(describing: $0) } == ["100", "A"])

        let mysql = built.prepare(.mysql)
        let directMySQL = direct.prepare(.mysql)
        #expect(mysql.plain == directMySQL.plain)
        #expect(
            mysql.plain ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= 100) ON trades.symbol = 'A'"
        )
        #expect(mysql.splitted.query == directMySQL.splitted.query)
        #expect(
            mysql.splitted.query ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= ?) ON trades.symbol = ?"
        )
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["100", "A"])
        #expect(directMySQL.splitted.values.map { String(describing: $0) } == ["100", "A"])
    }

    @Test("Stored MATCH_CONDITION and USING roles preserve structural columns")
    func storedMatchConditionUsingBuilderComposition() {
        let trades = Path.Table("trades")
        let prices = Path.Table("prices")
        let base = SwifQL.select(trades.column("id")).from(trades)
        let temporal = trades.column("event_time") >= 100
        let columns: [KeyPathLastPath] = [
            trades.column("symbol"),
            trades.column("event_time")
        ]
        let storedJoin = SwifQLJoinBuilder(
            .asOf,
            prices,
            matchCondition: temporal,
            using: columns
        )

        let built = SwifQLSelectBuilder()
            .select(trades.column("id"))
            .from(trades)
            .join(storedJoin)
            .build()
        let direct = base.join(
            .asOf,
            prices,
            matchCondition: temporal,
            using: trades.column("symbol"),
            trades.column("event_time")
        )

        let psql = built.prepare(.psql)
        let directPsql = direct.prepare(.psql)
        #expect(psql.plain == directPsql.plain)
        #expect(
            psql.plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= 100) USING ("symbol", "event_time")"#
        )
        #expect(psql.splitted.query == directPsql.splitted.query)
        #expect(
            psql.splitted.query ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= $1) USING ("symbol", "event_time")"#
        )
        #expect(psql.splitted.values.map { String(describing: $0) } == ["100"])
        #expect(directPsql.splitted.values.map { String(describing: $0) } == ["100"])

        let mysql = built.prepare(.mysql)
        let directMySQL = direct.prepare(.mysql)
        #expect(mysql.plain == directMySQL.plain)
        #expect(
            mysql.plain ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= 100) USING (symbol, event_time)"
        )
        #expect(mysql.splitted.query == directMySQL.splitted.query)
        #expect(
            mysql.splitted.query ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= ?) USING (symbol, event_time)"
        )
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["100"])
        #expect(directMySQL.splitted.values.map { String(describing: $0) } == ["100"])
    }

    @Test("Legacy ON-only stored join builders retain established output")
    func legacyOnOnlyBuilderComposition() {
        let trades = Path.Table("trades")
        let prices = Path.Table("prices")
        let equality = trades.column("symbol") == "A"
        let storedJoin = SwifQLJoinBuilder(.asOf, prices, on: equality)
        let built = SwifQLSelectBuilder()
            .select(trades.column("id"))
            .from(trades)
            .join(storedJoin)
            .build()

        let psql = built.prepare(.psql)
        #expect(
            psql.plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" ON "trades"."symbol" = 'A'"#
        )
        #expect(
            psql.splitted.query ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" ON "trades"."symbol" = $1"#
        )
        #expect(psql.splitted.values.map { String(describing: $0) } == ["A"])

        let mysql = built.prepare(.mysql)
        #expect(
            mysql.plain ==
                "SELECT trades.id FROM trades ASOF JOIN prices ON trades.symbol = 'A'"
        )
        #expect(
            mysql.splitted.query ==
                "SELECT trades.id FROM trades ASOF JOIN prices ON trades.symbol = ?"
        )
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["A"])
    }

    @Test("Copied select builders preserve stored MATCH_CONDITION join state")
    func copiedStoredMatchConditionBuilderComposition() {
        let trades = Path.Table("trades")
        let prices = Path.Table("prices")
        let temporal = trades.column("event_time") >= 100
        let equality = trades.column("symbol") == "A"
        let storedJoin = SwifQLJoinBuilder(
            .asOf,
            prices,
            matchCondition: temporal,
            on: equality
        )
        let builder = SwifQLSelectBuilder()
            .select(trades.column("id"))
            .from(trades)
            .join(storedJoin)
        let copied = builder.copy()
        let original = builder.build()
        let copy = copied.build()

        let originalPsql = original.prepare(.psql)
        let copyPsql = copy.prepare(.psql)
        #expect(originalPsql.plain == copyPsql.plain)
        #expect(
            originalPsql.plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= 100) ON "trades"."symbol" = 'A'"#
        )
        #expect(originalPsql.splitted.query == copyPsql.splitted.query)
        #expect(
            originalPsql.splitted.query ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= $1) ON "trades"."symbol" = $2"#
        )
        #expect(originalPsql.splitted.values.map { String(describing: $0) } == ["100", "A"])
        #expect(copyPsql.splitted.values.map { String(describing: $0) } == ["100", "A"])

        let originalMySQL = original.prepare(.mysql)
        let copyMySQL = copy.prepare(.mysql)
        #expect(originalMySQL.plain == copyMySQL.plain)
        #expect(
            originalMySQL.plain ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= 100) ON trades.symbol = 'A'"
        )
        #expect(originalMySQL.splitted.query == copyMySQL.splitted.query)
        #expect(
            originalMySQL.splitted.query ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= ?) ON trades.symbol = ?"
        )
        #expect(originalMySQL.splitted.values.map { String(describing: $0) } == ["100", "A"])
        #expect(copyMySQL.splitted.values.map { String(describing: $0) } == ["100", "A"])
    }
}
