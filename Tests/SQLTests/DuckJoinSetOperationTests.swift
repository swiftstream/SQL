import Foundation
import Testing
@testable import SQL

@Suite("Duck join and set operations")
struct DuckJoinSetOperationTests: SwifQLTests {
    private func table(_ name: String) -> Path.Table {
        Path.Table(name)
    }

    private func selection(from name: String) -> SwifQLable {
        let source = table(name)
        return SwifQL.select(source.column("id")).from(source)
    }

    private func root(of query: SwifQLable) -> SwifQLStructuralFramePart {
        query.parts.first as! SwifQLStructuralFramePart
    }

    private func orderByPart(in frame: SwifQLStructuralFramePart) -> SwifQLOrderByPart? {
        frame.children.compactMap { $0 as? SwifQLOrderByPart }.first
    }

    private func containsOperator(
        _ value: String,
        in parts: [SwifQLPart]
    ) -> Bool {
        parts.contains { part in
            if let operatorPart = part as? SwifQLPartOperator {
                return operatorPart._value == value
            }
            if let frame = part as? SwifQLStructuralFramePart {
                return containsOperator(value, in: frame.children)
            }
            return false
        }
    }

    private func columnNames(in parts: [SwifQLPart]) -> [String] {
        parts.flatMap { part in
            if let column = part as? SwifQLPartColumn {
                return [column.name]
            }
            if let frame = part as? SwifQLStructuralFramePart {
                return columnNames(in: frame.children)
            }
            return []
        }
    }

    @Test("Existing join modes and generic ON rendering remain exact")
    func historicalJoinCompatibility() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)
        let predicate = left.column("id") == right.column("id")

        check(
            base.join(.inner, right, on: predicate),
            .psql(#"SELECT "left_table"."id" FROM "left_table" INNER JOIN "right_table" ON "left_table"."id" = "right_table"."id""#),
            .mysql("SELECT left_table.id FROM left_table INNER JOIN right_table ON left_table.id = right_table.id")
        )
        check(
            base.join(.cross, right, on: predicate),
            .psql(#"SELECT "left_table"."id" FROM "left_table" CROSS JOIN "right_table" ON "left_table"."id" = "right_table"."id""#),
            .mysql("SELECT left_table.id FROM left_table CROSS JOIN right_table ON left_table.id = right_table.id")
        )
        check(
            base.join(.outer, right, on: predicate),
            .psql(#"SELECT "left_table"."id" FROM "left_table" OUTER JOIN "right_table" ON "left_table"."id" = "right_table"."id""#),
            .mysql("SELECT left_table.id FROM left_table OUTER JOIN right_table ON left_table.id = right_table.id")
        )
    }

    @Test("FULL SEMI ANTI and ASOF modes use exact SQL vocabulary")
    func additiveJoinModes() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)
        let predicate = left.column("id") == right.column("id")

        check(
            base.join(.full, right, on: predicate),
            .duck(#"SELECT "left_table"."id" FROM "left_table" FULL JOIN "right_table" ON "left_table"."id" = "right_table"."id""#)
        )
        check(
            base.join(.fullOuter, right, on: predicate),
            .duck(#"SELECT "left_table"."id" FROM "left_table" FULL OUTER JOIN "right_table" ON "left_table"."id" = "right_table"."id""#)
        )
        check(
            base.join(.semi, right, on: predicate),
            .duck(#"SELECT "left_table"."id" FROM "left_table" SEMI JOIN "right_table" ON "left_table"."id" = "right_table"."id""#)
        )
        check(
            base.join(.anti, right, on: predicate),
            .duck(#"SELECT "left_table"."id" FROM "left_table" ANTI JOIN "right_table" ON "left_table"."id" = "right_table"."id""#)
        )
        check(
            base.join(.asOf, right, on: predicate),
            .duck(#"SELECT "left_table"."id" FROM "left_table" ASOF JOIN "right_table" ON "left_table"."id" = "right_table"."id""#)
        )
        check(
            base.join(.asOfLeft, right, on: predicate),
            .duck(#"SELECT "left_table"."id" FROM "left_table" ASOF LEFT JOIN "right_table" ON "left_table"."id" = "right_table"."id""#)
        )
    }

    @Test("Verified LATERAL forms preserve token order")
    func lateralForms() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)
        let lateral = |SwifQL.select(right.column("id")).from(right)|

        check(
            base.join(.leftLateral, lateral, on: SwifQLPartBool(true)),
            .duck(#"SELECT "left_table"."id" FROM "left_table" LEFT JOIN LATERAL (SELECT "right_table"."id" FROM "right_table") ON TRUE"#)
        )
        check(
            base.join(.leftOuterLateral, lateral, on: SwifQLPartBool(true)),
            .duck(#"SELECT "left_table"."id" FROM "left_table" LEFT OUTER JOIN LATERAL (SELECT "right_table"."id" FROM "right_table") ON TRUE"#)
        )
        check(
            base.join(.crossLateral, lateral),
            .duck(#"SELECT "left_table"."id" FROM "left_table" CROSS JOIN LATERAL (SELECT "right_table"."id" FROM "right_table")"#)
        )
    }

    @Test("SEMI and ANTI USING render structural identifiers")
    func semiAntiUsing() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)

        check(
            base.join(.semi, right, using: left.column("id")),
            .duck(#"SELECT "left_table"."id" FROM "left_table" SEMI JOIN "right_table" USING ("id")"#)
        )
        check(
            base.join(.anti, right, using: left.column("id"), left.column("tenant")),
            .duck(#"SELECT "left_table"."id" FROM "left_table" ANTI JOIN "right_table" USING ("id", "tenant")"#)
        )
    }

    @Test("ASOF USING preserves caller column order without inference")
    func asOfUsing() {
        let trades = table("trades")
        let prices = table("prices")
        let base = SwifQL.select(trades.column("id")).from(trades)

        let query = base.join(
            .asOf,
            prices,
            using: trades.column("symbol"),
            trades.column("event_time")
        )

        check(
            query,
            .duck(#"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" USING ("symbol", "event_time")"#)
        )
    }

    @Test("Explicit MATCH_CONDITION remains distinct from ON and USING")
    func asOfMatchConditionRoles() {
        let trades = table("trades")
        let prices = table("prices")
        let base = SwifQL.select(trades.column("id")).from(trades)
        let temporal = trades.column("event_time") >= prices.column("event_time")
        let equality = trades.column("symbol") == prices.column("symbol")

        let matchOn = base.join(
            .asOf,
            prices,
            matchCondition: temporal,
            on: equality
        )
        let matchUsing = base.join(
            .asOf,
            prices,
            matchCondition: temporal,
            using: trades.column("symbol"),
            trades.column("event_time")
        )
        let oldOn = base.join(.asOf, prices, on: equality)

        #expect(
            matchOn.prepare(.duck).plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= "prices"."event_time") ON "trades"."symbol" = "prices"."symbol""#
        )
        #expect(
            matchUsing.prepare(.duck).plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= "prices"."event_time") USING ("symbol", "event_time")"#
        )
        #expect(
            matchOn.prepare(.psql).plain ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= "prices"."event_time") ON "trades"."symbol" = "prices"."symbol""#
        )
        #expect(
            matchOn.prepare(.mysql).plain ==
                "SELECT trades.id FROM trades ASOF JOIN prices MATCH_CONDITION (trades.event_time >= prices.event_time) ON trades.symbol = prices.symbol"
        )
        #expect(oldOn.prepare(.duck).plain.contains(" MATCH_CONDITION ") == false)

        let boundTemporal = trades.column("event_time") >= 100
        let boundEquality = trades.column("symbol") == "A"
        let prepared = base
            .join(.asOf, prices, matchCondition: boundTemporal, on: boundEquality)
            .prepare(.duck)
        #expect(
            prepared.splitted.query ==
                #"SELECT "trades"."id" FROM "trades" ASOF JOIN "prices" MATCH_CONDITION ("trades"."event_time" >= $1) ON "trades"."symbol" = $2"#
        )
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["100", "A"])
        #expect(matchUsing.prepare(.duck).splitted.values.isEmpty)

        func addJoin(_ query: SwifQLable) -> SwifQLable {
            query.join(
                .asOf,
                prices,
                matchCondition: temporal,
                on: equality
            )
        }
        let direct = addJoin(base)
        let erased: SwifQLable = direct
        let copied = SwifQLableParts(parts: erased.parts)
        var conditional: SwifQLable = base
        if true {
            conditional = addJoin(conditional)
        }
        for query in [direct, erased, copied, conditional] {
            #expect(query.prepare(.duck).plain == direct.prepare(.duck).plain)
            #expect(query.prepare(.duck).splitted.query == direct.prepare(.duck).splitted.query)
        }
    }

    @Test("POSITIONAL and NATURAL modes preserve conditionless JOIN output")
    func conditionlessJoinForms() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)

        check(
            base.join(.positional, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" POSITIONAL JOIN "right_table""#)
        )
        check(
            base.join(.natural, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" NATURAL JOIN "right_table""#)
        )
        check(
            base.join(.naturalInner, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" NATURAL INNER JOIN "right_table""#)
        )
        check(
            base.join(.naturalLeft, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" NATURAL LEFT JOIN "right_table""#)
        )
        check(
            base.join(.naturalRight, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" NATURAL RIGHT JOIN "right_table""#)
        )
        check(
            base.join(.naturalFull, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" NATURAL FULL JOIN "right_table""#)
        )
        check(
            base.join(.naturalFullOuter, right),
            .duck(#"SELECT "left_table"."id" FROM "left_table" NATURAL FULL OUTER JOIN "right_table""#)
        )
    }

    @Test("USING keeps only last-path identifiers and never creates binds")
    func usingIdentifierSafety() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)
        let qualified = Path.Schema("analytics").table("source").column("tenant")
        let columns: [KeyPathLastPath] = ["select", "имя", "a\"b"]

        let qualifiedQuery = base.join(.left, right, using: left.column("id"), qualified)
        #expect(columnNames(in: qualifiedQuery.parts) == ["id", "tenant"])
        #expect(qualifiedQuery.prepare(.duck).splitted.values.isEmpty)
        #expect(
            qualifiedQuery.prepare(.duck).plain ==
                #"SELECT "left_table"."id" FROM "left_table" LEFT JOIN "right_table" USING ("id", "tenant")"#
        )

        let quotedQuery = base.join(right, using: columns)
        #expect(columnNames(in: quotedQuery.parts) == ["select", "имя", "a\"b"])
        #expect(quotedQuery.prepare(.duck).splitted.values.isEmpty)
        #expect(
            quotedQuery.prepare(.duck).plain ==
                #"SELECT "left_table"."id" FROM "left_table" JOIN "right_table" USING ("select", "имя", "a""b")"#
        )
    }

    @Test("JOIN ON prepared values retain left-to-right bind order")
    func joinPreparedBindOrder() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)
        let predicate = (left.column("id") == 7) && (right.column("tenant") == "tenant")
        let query = base.join(.left, right, on: predicate)
        let prepared = query.prepare(.duck).splitted

        #expect(
            prepared.query ==
                #"SELECT "left_table"."id" FROM "left_table" LEFT JOIN "right_table" ON "left_table"."id" = $1 AND "right_table"."tenant" = $2"#
        )
        #expect(prepared.values.map { String(describing: $0) } == ["7", "tenant"])
    }

    @Test("Fluent variable helper and copied join composition are invariant")
    func joinCompositionInvariance() {
        let left = table("left_table")
        let right = table("right_table")
        let base = SwifQL.select(left.column("id")).from(left)

        func addJoin(_ query: SwifQLable) -> SwifQLable {
            query.join(.semi, right, using: left.column("id"))
        }

        let fluent = addJoin(base)
        var variable: SwifQLable = base
        variable = addJoin(variable)
        let copied = SwifQLableParts(parts: variable.parts)

        #expect(fluent.prepare(.duck).plain == variable.prepare(.duck).plain)
        #expect(variable.prepare(.duck).plain == copied.prepare(.duck).plain)
        #expect(root(of: copied).region == .statement)
    }

    @Test("Historical UNION and UNION ALL output remains exact")
    func historicalUnionCompatibility() {
        let lhs = selection(from: "left_table")
        let rhs = selection(from: "right_table")

        check(
            Union(lhs, rhs),
            .psql(#"(SELECT "left_table"."id" FROM "left_table") UNION (SELECT "right_table"."id" FROM "right_table")"#),
            .mysql("(SELECT left_table.id FROM left_table) UNION (SELECT right_table.id FROM right_table)")
        )
        check(
            Union(all: lhs, rhs),
            .psql(#"(SELECT "left_table"."id" FROM "left_table") UNION ALL (SELECT "right_table"."id" FROM "right_table")"#),
            .mysql("(SELECT left_table.id FROM left_table) UNION ALL (SELECT right_table.id FROM right_table)")
        )
    }

    @Test("All new set operations render exact SQL")
    func setOperationSQL() {
        let lhs = selection(from: "left_table")
        let rhs = selection(from: "right_table")

        check(
            lhs.union(byName: rhs),
            .duck(#"(SELECT "left_table"."id" FROM "left_table") UNION BY NAME (SELECT "right_table"."id" FROM "right_table")"#)
        )
        check(
            lhs.union(allByName: rhs),
            .duck(#"(SELECT "left_table"."id" FROM "left_table") UNION ALL BY NAME (SELECT "right_table"."id" FROM "right_table")"#)
        )
        check(
            lhs.intersect(rhs),
            .duck(#"(SELECT "left_table"."id" FROM "left_table") INTERSECT (SELECT "right_table"."id" FROM "right_table")"#)
        )
        check(
            lhs.intersect(all: rhs),
            .duck(#"(SELECT "left_table"."id" FROM "left_table") INTERSECT ALL (SELECT "right_table"."id" FROM "right_table")"#)
        )
        check(
            lhs.except(rhs),
            .duck(#"(SELECT "left_table"."id" FROM "left_table") EXCEPT (SELECT "right_table"."id" FROM "right_table")"#)
        )
        check(
            lhs.except(all: rhs),
            .duck(#"(SELECT "left_table"."id" FROM "left_table") EXCEPT ALL (SELECT "right_table"."id" FROM "right_table")"#)
        )
    }

    @Test("UNION BY NAME proves name alignment and NULL filling")
    func namedUnionAlignment() {
        let lhsParts: [SwifQLPart] = [
            SwifQLPartOperator.custom("SELECT 1 AS id, 'left' AS shared, 'only_left' AS left_only")
        ]
        let rhsParts: [SwifQLPart] = [
            SwifQLPartOperator.custom("SELECT 'right' AS shared, 2 AS id, 'only_right' AS right_only")
        ]
        let lhs = SwifQLableParts(parts: lhsParts)
        let rhs = SwifQLableParts(parts: rhsParts)
        let query = lhs.union(byName: rhs)

        #expect(
            query.prepare(.duck).plain ==
                "(SELECT 1 AS id, 'left' AS shared, 'only_left' AS left_only) UNION BY NAME (SELECT 'right' AS shared, 2 AS id, 'only_right' AS right_only)"
        )
    }

    @Test("Set-operation prepared values retain operand order")
    func setOperationPreparedBindOrder() {
        let left = table("left_table")
        let right = table("right_table")
        let lhs = SwifQL.select(left.column("id")).from(left).where(left.column("kind") == "left")
        let rhs = SwifQL.select(right.column("id")).from(right).where(right.column("kind") == "right")
        let query = lhs.intersect(rhs)
        let prepared = query.prepare(.duck).splitted

        #expect(
            prepared.query ==
                #"(SELECT "left_table"."id" FROM "left_table" WHERE "left_table"."kind" = $1) INTERSECT (SELECT "right_table"."id" FROM "right_table" WHERE "right_table"."kind" = $2)"#
        )
        #expect(prepared.values.map { String(describing: $0) } == ["left", "right"])
    }

    @Test("Final ORDER BY and LIMIT belong to every new set-result root")
    func setResultOwnership() {
        let lhs = selection(from: "left_table")
        let rhs = selection(from: "right_table")
        let order = OrderByItem.asc(table("left_table").column("id"))
        let operations: [SwifQLable] = [
            lhs.union(byName: rhs),
            lhs.union(allByName: rhs),
            lhs.intersect(rhs),
            lhs.intersect(all: rhs),
            lhs.except(rhs),
            lhs.except(all: rhs)
        ]

        for operation in operations {
            let final = operation.orderBy(order).limit(2)
            let frame = root(of: final)
            let operands = frame.children.compactMap { $0 as? SwifQLStructuralFramePart }

            #expect(frame.region == .setResult)
            #expect(operands.count == 2)
            #expect(orderByPart(in: frame) != nil)
            #expect(orderByPart(in: operands[1]) == nil)
            #expect(containsOperator("LIMIT", in: frame.children))
            #expect(!containsOperator("LIMIT", in: operands[1].children))
        }
    }

    @Test("Operand-local ORDER BY and LIMIT remain inside its statement frame")
    func operandLocalClauses() {
        let lhs = selection(from: "left_table")
        let rightTable = table("right_table")
        let rhs = SwifQL
            .select(rightTable.column("id"))
            .from(rightTable)
            .orderBy(.desc(rightTable.column("id")))
            .limit(1)
        let query = lhs.union(byName: rhs)
        let frame = root(of: query)
        let operands = frame.children.compactMap { $0 as? SwifQLStructuralFramePart }

        #expect(operands.count == 2)
        #expect(orderByPart(in: frame) == nil)
        #expect(orderByPart(in: operands[1]) != nil)
        #expect(containsOperator("LIMIT", in: operands[1].children))
        #expect(
            query.prepare(.duck).plain ==
                #"(SELECT "left_table"."id" FROM "left_table") UNION BY NAME (SELECT "right_table"."id" FROM "right_table" ORDER BY "right_table"."id" DESC LIMIT 1)"#
        )
    }

    @Test("Chained set operations preserve explicit nested ownership")
    func chainedSetOperations() {
        let lhs = selection(from: "left_table")
        let rhs = selection(from: "right_table")
        let third = selection(from: "third_table")
        let query = lhs.union(byName: rhs).intersect(all: third)
        let frame = root(of: query)
        let operands = frame.children.compactMap { $0 as? SwifQLStructuralFramePart }

        #expect(frame.region == .setResult)
        #expect(operands.count == 2)
        #expect(
            operands[0].children.contains {
                ($0 as? SwifQLStructuralFramePart)?.region == .setResult
            }
        )
        #expect(
            query.prepare(.duck).plain ==
                #"((SELECT "left_table"."id" FROM "left_table") UNION BY NAME (SELECT "right_table"."id" FROM "right_table")) INTERSECT ALL (SELECT "third_table"."id" FROM "third_table")"#
        )
    }

    @Test("Copied and helper-composed set results keep structural invariants")
    func copiedSetComposition() {
        let lhs = selection(from: "left_table")
        let rhs = selection(from: "right_table")

        func makeSet(_ left: SwifQLable, _ right: SwifQLable) -> SwifQLable {
            left.except(all: right)
        }

        var query: SwifQLable = lhs
        query = makeSet(query, rhs)
        let copied = SwifQLableParts(parts: query.parts)
        let frame = root(of: copied)
        let operands = frame.children.compactMap { $0 as? SwifQLStructuralFramePart }

        #expect(frame.region == .setResult)
        #expect(operands.count == 2)
        #expect(copied.prepare(.duck).plain == query.prepare(.duck).plain)
    }
}
