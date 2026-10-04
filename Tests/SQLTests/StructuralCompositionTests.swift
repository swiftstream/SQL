import Foundation
import Testing
@testable import SQL

@Suite("Structural composition")
struct StructuralCompositionTests {
    private let kind = SwifQLClauseKind(namespace: "example", name: "clause")
    private let owner = SwifQLClauseOwner(namespace: "example", name: "region")

    @Test("Open owner and clause-kind values are readable")
    func openValues() {
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [kind: owner],
            children: [SwifQLPartOperator.custom("SELECT")]
        )

        #expect(frame.owner(for: kind) == owner)
        #expect(SwifQLableParts(parts: frame).structuralOwner(for: kind) == owner)
    }

    @Test("Ownership lookup reads only the root frame")
    func rootOnlyLookup() {
        let nestedOwner = SwifQLClauseOwner(namespace: "nested", name: "region")
        let nested = SwifQLStructuralFramePart(
            region: .statement,
            owners: [kind: nestedOwner]
        )
        let outer = SwifQLStructuralFramePart(
            region: .statement,
            children: [nested]
        )

        #expect(SwifQLableParts(parts: outer).structuralOwner(for: kind) == nil)
    }

    @Test("Framed continuation is value-semantic")
    func framedContinuation() {
        let base = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [kind: owner],
            children: [SwifQLPartOperator.custom("SELECT")]
        ))
        let fragmentParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("TAIL")
        ]
        let fragment = SwifQLableParts(parts: fragmentParts)

        let continued = base.structurallyAppending(fragment)
        let baseFrame = base.parts.first as? SwifQLStructuralFramePart
        let continuedFrame = continued.parts.first as? SwifQLStructuralFramePart

        #expect(baseFrame?.children.count == 1)
        #expect(continuedFrame?.children.count == 3)
        #expect(continued.structuralOwner(for: kind) == owner)
    }

    @Test("Independently framed roots stay independent")
    func independentRoots() {
        let first = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [kind: owner]
        ))
        let secondOwner = SwifQLClauseOwner(namespace: "other", name: "region")
        let second = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [kind: secondOwner]
        ))

        let combined = first ~ second

        #expect(combined.parts.count == 2)
        #expect((combined.parts[0] as? SwifQLStructuralFramePart)?.owner(for: kind) == owner)
        #expect((combined.parts[1] as? SwifQLStructuralFramePart)?.owner(for: kind) == secondOwner)
    }

    @Test("Unframed concatenation remains flat")
    func unframedConcatenation() {
        let lhs = SwifQLableParts(parts: SwifQLPartOperator.custom("LEFT"))
        let rhsParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("RIGHT")
        ]
        let rhs = SwifQLableParts(parts: rhsParts)

        let combined = lhs ~ rhs

        #expect(combined.parts.count == 3)
        #expect(combined.prepare(.psql).plain == "LEFT RIGHT")
    }

    @Test("Expression parentheses are not structural frames")
    func expressionParentheses() {
        let table = Path.Table("events")
        let expression = |(table.column("year") + 1)|

        #expect(expression.parts.first is SwifQLStructuralFramePart == false)
    }

    @Test("Neutral framing preserves representative SQL and bind order")
    func compatibility() {
        let table = Path.Table("users")
        let id = table.column("id")
        let name = table.column("name")
        let age = table.column("age")
        let score = table.column("score")
        let query = SwifQL
            .select(id, name, Fn.count(score))
            .from(table)
            .where(age > 18 && name != "Ada")
            .groupBy(name)
            .having(Fn.count(score) > 1)
            .orderBy(.asc(name), .desc(id, nulls: .last))
            .limit(10)
            .offset(5)

        let psql = query.prepare(.psql)
        #expect(psql.plain == #"SELECT "users"."id", "users"."name", count("users"."score") FROM "users" WHERE "users"."age" > 18 AND "users"."name" != 'Ada' GROUP BY "users"."name" HAVING count("users"."score") > 1 ORDER BY "users"."name" ASC, "users"."id" DESC NULLS LAST LIMIT 10 OFFSET 5"#)
        #expect(psql.splitted.query == #"SELECT "users"."id", "users"."name", count("users"."score") FROM "users" WHERE "users"."age" > $1 AND "users"."name" != $2 GROUP BY "users"."name" HAVING count("users"."score") > $3 ORDER BY "users"."name" ASC, "users"."id" DESC NULLS LAST LIMIT $4 OFFSET $5"#)
        #expect(psql.splitted.values.map { String(describing: $0) } == ["18", "Ada", "1", "10", "5"])

        let mysql = query.prepare(.mysql)
        #expect(mysql.plain == "SELECT users.id, users.name, count(users.score) FROM users WHERE users.age > 18 AND users.name != 'Ada' GROUP BY users.name HAVING count(users.score) > 1 ORDER BY users.name ASC, users.id DESC NULLS LAST LIMIT 10 OFFSET 5")
        #expect(mysql.splitted.query == "SELECT users.id, users.name, count(users.score) FROM users WHERE users.age > ? AND users.name != ? GROUP BY users.name HAVING count(users.score) > ? ORDER BY users.name ASC, users.id DESC NULLS LAST LIMIT ? OFFSET ?")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["18", "Ada", "1", "10", "5"])
    }
}
