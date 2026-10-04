import Foundation
import Testing
@testable import SQL

private final class SimplifiedPivotScopeDialect: SQLDialect {
    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "qualified"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        if context.contains(.simplifiedPivotOn) {
            return "on-scope"
        }
        if context.contains(.simplifiedPivotUsing) {
            return "using-scope"
        }
        if context.contains(.simplifiedPivotGroupBy) {
            return "group-scope"
        }
        if context.contains(.simplifiedPivotOrderBy) {
            return "order-scope"
        }
        return "qualified"
    }
}

private final class OwnerDerivedClauseScopeDialect: SQLDialect {
    private let onScope: SwifQLRenderScope
    private let usingScope: SwifQLRenderScope

    init(owner: SwifQLClauseOwner) {
        self.onScope = owner.renderScope(for: .on)
        self.usingScope = owner.renderScope(for: .using)
        super.init()
    }

    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "qualified"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        if context.contains(onScope) {
            return "custom-on-scope"
        }
        if context.contains(usingScope) {
            return "custom-using-scope"
        }
        return "qualified"
    }
}

@Suite("Duck simplified PIVOT")
struct DuckPivotTests {
    private let cities = Path.Table("cities")

    private func target() -> SwifQLable {
        var query: SwifQLable = SwifQL
        query = query.pivot(cities)
        query = query.on(cities.column("year"), in: 2000, 2010)
        query = query.using(Fn.sum(cities.column("population")) => "total")
        query = query.groupBy(cities.column("country"))
        query = query.orderBy(.desc(cities.column("country")))
        query = query.limit(2)
        return query
    }

    private func fluentTarget() -> SwifQLable {
        SwifQL
            .pivot(cities)
            .on(cities.column("year"), in: 2000, 2010)
            .using(Fn.sum(cities.column("population")) => "total")
            .groupBy(cities.column("country"))
            .orderBy(.desc(cities.column("country")))
            .limit(2)
    }

    private func root(of query: SwifQLable) -> SwifQLStructuralFramePart {
        query.parts.first as! SwifQLStructuralFramePart
    }

    private func children(of query: SwifQLable) -> [SwifQLPart] {
        root(of: query).children
    }

    private func groupByPart(in query: SwifQLable) -> SwifQLGroupByPart? {
        children(of: query).compactMap { $0 as? SwifQLGroupByPart }.first
    }

    private func orderByPart(in query: SwifQLable) -> SwifQLOrderByPart? {
        children(of: query).compactMap { $0 as? SwifQLOrderByPart }.first
    }

    @Test("Fluent and erased target source preserve exact Duck SQL and bind order")
    func exactTargetSource() {
        let erased = target()
        let fluent = fluentTarget()
        let expectedPlain = #"PIVOT "cities" ON "year" IN (2000, 2010) USING sum("population") as "total" GROUP BY "country" ORDER BY "country" DESC LIMIT 2"#
        let expectedQuery = #"PIVOT "cities" ON "year" IN ($1, $2) USING sum("population") as "total" GROUP BY "country" ORDER BY "country" DESC LIMIT $3"#

        #expect(erased.prepare(.duck).plain == expectedPlain)
        #expect(fluent.prepare(.duck).plain == expectedPlain)
        #expect(erased.prepare(.duck).splitted.query == expectedQuery)
        #expect(fluent.prepare(.duck).splitted.query == expectedQuery)
        #expect(erased.prepare(.duck).splitted.values.map { String(describing: $0) } == ["2000", "2010", "2"])
        #expect(fluent.prepare(.duck).splitted.values.map { String(describing: $0) } == ["2000", "2010", "2"])
    }

    @Test("Public simplified-PIVOT identities are distinct and value-semantic")
    func publicIdentities() {
        #expect(SwifQLClauseOwner.simplifiedPivot.namespace == "swifql")
        #expect(SwifQLClauseOwner.simplifiedPivot.name == "simplifiedPivot")
        #expect(SwifQLClauseKind.on == SwifQLClauseKind(namespace: "swifql", name: "on"))
        #expect(SwifQLClauseKind.using == SwifQLClauseKind(namespace: "swifql", name: "using"))

        let scopes: Set<SwifQLRenderScope> = [
            .simplifiedPivotOn,
            .simplifiedPivotUsing,
            .simplifiedPivotGroupBy,
            .simplifiedPivotOrderBy
        ]
        #expect(scopes.count == 4)
        #expect(SwifQLRenderScope.simplifiedPivotOn != .simplifiedPivotUsing)
        #expect(SwifQLRenderScope.simplifiedPivotGroupBy != .simplifiedPivotOrderBy)
        #expect(.simplifiedPivotOn == SwifQLClauseOwner.simplifiedPivot.renderScope(for: .on))
        #expect(.simplifiedPivotUsing == SwifQLClauseOwner.simplifiedPivot.renderScope(for: .using))
        #expect(.simplifiedPivotGroupBy == SwifQLClauseOwner.simplifiedPivot.renderScope(for: .groupBy))
        #expect(.simplifiedPivotOrderBy == SwifQLClauseOwner.simplifiedPivot.renderScope(for: .orderBy))
        #expect(SwifQLClauseOwner.simplifiedPivot == SwifQLClauseOwner(
            namespace: "swifql",
            name: "simplifiedPivot"
        ))
    }

    @Test("ON and USING scopes are bounded to their supplied expression subtrees")
    func boundedScopes() {
        let query = SwifQL
            .pivot(cities)
            .on(cities.column("year"), in: 2000)
            .using(Fn.sum(cities.column("population")) => "total")
            .groupBy(cities.column("country"))
            .orderBy(.desc(cities.column("country")))

        #expect(
            query.prepare(SimplifiedPivotScopeDialect()).plain
                == "PIVOT cities ON on-scope IN (2000) USING sum(using-scope) as total GROUP BY group-scope ORDER BY order-scope DESC"
        )

        let nested = SwifQL.select(cities.column("year")).from(cities)
        let nestedOn = SwifQL.pivot(cities).on(nested)
        #expect(nestedOn.prepare(.duck).plain == #"PIVOT "cities" ON SELECT "cities"."year" FROM "cities""#)
    }

    @Test("Simplified-PIVOT ON scope does not leak into explicit IN expressions")
    func onScopeDoesNotLeakIntoInValues() {
        let query = SwifQL
            .pivot(cities)
            .on(cities.column("year"), in: cities.column("id"))

        #expect(
            query.prepare(SimplifiedPivotScopeDialect()).plain
                == "PIVOT cities ON on-scope IN (qualified)"
        )
    }

    @Test("Structural owners persist through dedicated clauses and copied parts")
    func structuralOwners() {
        let pivoted = SwifQL.pivot(cities)
        let unrelated = SwifQLClauseKind(namespace: "example", name: "unrelated")

        #expect(pivoted.structuralOwner(for: .on) == .simplifiedPivot)
        #expect(pivoted.structuralOwner(for: .using) == .simplifiedPivot)
        #expect(pivoted.structuralOwner(for: .groupBy) == .simplifiedPivot)
        #expect(pivoted.structuralOwner(for: .orderBy) == .simplifiedPivot)
        #expect(pivoted.structuralOwner(for: unrelated) == nil)

        let grouped = pivoted.groupBy(cities.column("country"))
        let ordered = grouped.orderBy(.desc(cities.column("country")))
        let copied = SwifQLableParts(parts: ordered.parts)

        #expect(groupByPart(in: copied)?.owner == .simplifiedPivot)
        #expect(orderByPart(in: copied)?.owner == .simplifiedPivot)
        #expect(copied.structuralOwner(for: .groupBy) == .simplifiedPivot)
        #expect(copied.structuralOwner(for: .orderBy) == .simplifiedPivot)
    }

    @Test("Helpers, conditionals, and copied stages preserve one composition")
    func helperAndCopiedComposition() {
        func source(_ value: SwifQLable) -> SwifQLable { value }
        func aggregate(_ value: SwifQLable) -> SwifQLable { Fn.sum(value) => "total" }

        let sourcePart = source(cities)
        let aggregatePart = aggregate(cities.column("population"))
        var query: SwifQLable = SwifQL
        query = query.pivot(sourcePart)
        let copiedAfterPivot = SwifQLableParts(parts: query.parts)
        query = copiedAfterPivot.on(cities.column("year"), in: 2000, 2010)
        let copiedAfterOn = SwifQLableParts(parts: query.parts)
        if true {
            query = copiedAfterOn.using(aggregatePart)
        }
        let copiedAfterUsing = SwifQLableParts(parts: query.parts)
        query = copiedAfterUsing.groupBy(cities.column("country"))
        let copiedAfterGroup = SwifQLableParts(parts: query.parts)
        query = copiedAfterGroup.orderBy(.desc(cities.column("country")))
        let copiedAfterOrder = SwifQLableParts(parts: query.parts)
        query = copiedAfterOrder.limit(2)

        #expect(query.prepare(.duck).plain == target().prepare(.duck).plain)
        #expect(query.prepare(.duck).splitted.query == target().prepare(.duck).splitted.query)
        #expect(query.prepare(.duck).splitted.values.map { String(describing: $0) } == ["2000", "2010", "2"])
    }

    @Test("Nested PIVOT, ordinary queries, CTEs, and set results isolate owners")
    func nestedOwnershipIsolation() {
        let inner = target()
        let outer = SwifQL.pivot(inner)
        let outerRoot = root(of: outer)
        let nestedPivotFrames = outerRoot.children.compactMap { $0 as? SwifQLStructuralFramePart }

        #expect(outerRoot.owner(for: .groupBy) == .simplifiedPivot)
        #expect(nestedPivotFrames.contains { $0.owner(for: .groupBy) == .simplifiedPivot })

        let ordinary = SwifQL.select(inner)
        #expect(root(of: ordinary).owner(for: .groupBy) == nil)
        #expect(root(of: ordinary).children.contains { part in
            (part as? SwifQLStructuralFramePart)?.owner(for: .groupBy) == .simplifiedPivot
        })

        let cte = SwifQL
            .with(.init(Path.Table("pivoted"), inner))
            .select(Path.Table("pivoted").column("country"))
            .from(Path.Table("pivoted"))
        #expect(root(of: cte).owner(for: .groupBy) == nil)
        #expect(root(of: cte).children.contains { part in
            (part as? SwifQLStructuralFramePart)?.owner(for: .groupBy) == .simplifiedPivot
        })

        let union = Union([inner, SwifQL.select(1)])
        let unionRoot = root(of: union)
        #expect(unionRoot.region == .setResult)
        #expect(unionRoot.owner(for: .groupBy) == nil)
        #expect(unionRoot.children.contains { part in
            (part as? SwifQLStructuralFramePart)?.owner(for: .groupBy) == .simplifiedPivot
        })
        #expect(union.groupBy(cities.column("country")).structuralOwner(for: .groupBy) == nil)

        let outerOn = SwifQL.select(SwifQL.pivot(cities)).on(cities.column("id"))
        let outerUsing = SwifQL.select(SwifQL.pivot(cities)).using(cities.column("id"))
        #expect(outerOn.prepare(SimplifiedPivotScopeDialect()).plain == "SELECT PIVOT cities ON qualified")
        #expect(outerUsing.prepare(SimplifiedPivotScopeDialect()).plain == "SELECT PIVOT cities USING qualified")
    }

    @Test("Nested simplified-PIVOT ownership does not leak into outer Duck ON and USING")
    func nestedPivotDoesNotLeakUnderDuck() {
        let outerOn = SwifQL.select(SwifQL.pivot(cities)).on(cities.column("id"))
        let outerUsing = SwifQL.select(SwifQL.pivot(cities)).using(cities.column("id"))

        #expect(outerOn.prepare(.duck).plain == #"SELECT PIVOT "cities" ON "cities"."id""#)
        #expect(outerUsing.prepare(.duck).plain == #"SELECT PIVOT "cities" USING "cities"."id""#)
    }

    @Test("No-IN form is exact and never synthesizes an empty IN list")
    func noInForm() {
        let query = SwifQL
            .pivot(cities)
            .on(cities.column("year"))
            .using(Fn.sum(cities.column("population")))
            .groupBy(cities.column("country"))

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == #"PIVOT "cities" ON "year" USING sum("population") GROUP BY "country""#)
        #expect(!prepared.plain.contains("IN ()"))
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("Ordinary unowned ON and USING preserve qualified paths in every established dialect")
    func qualificationNegatives() {
        let customScope = SwifQLRenderScope(namespace: "example", name: "ordinary")
        let path = cities.column("country")

        #expect(SwifQL.select(path.scoped(customScope)).prepare(.duck).plain == #"SELECT "cities"."country""#)

        let customOwner = SwifQLClauseOwner(namespace: "example", name: "region")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: customOwner, .orderBy: customOwner],
            children: [SwifQLPartOperator.custom("BASE")]
        )
        let ordinary = SwifQLableParts(parts: frame)
            .groupBy(path)
            .orderBy(.asc(path))
        #expect(ordinary.prepare(.duck).plain == #"BASE GROUP BY "cities"."country" ORDER BY "cities"."country" ASC"#)

        let unowned = SwifQLableParts(parts: SwifQLPartOperator.custom("BASE"))
        let on = unowned.on(cities.column("id"))
        let using = unowned.using(cities.column("id"))

        #expect(unowned.structuralOwner(for: .on) == nil)
        #expect(unowned.structuralOwner(for: .using) == nil)
        #expect(unowned.structuralOwner(for: .groupBy) == nil)
        #expect(unowned.structuralOwner(for: .orderBy) == nil)
        #expect(on.prepare(.duck).plain == #"BASE ON "cities"."id""#)
        #expect(using.prepare(.duck).plain == #"BASE USING "cities"."id""#)
        #expect(on.prepare(.psql).plain == #"BASE ON "cities"."id""#)
        #expect(using.prepare(.psql).plain == #"BASE USING "cities"."id""#)
        #expect(on.prepare(.mysql).plain == "BASE ON cities.id")
        #expect(using.prepare(.mysql).plain == "BASE USING cities.id")
    }

    @Test("Ordinary unowned ON with IN preserves qualification and bind behavior")
    func ordinaryUnownedOnIn() {
        let base = SwifQLableParts(parts: SwifQLPartOperator.custom("BASE"))
        let query = base.on(cities.column("id"), in: 1)

        #expect(base.structuralOwner(for: .on) == nil)

        let duck = query.prepare(.duck)
        #expect(duck.plain == #"BASE ON "cities"."id" IN (1)"#)
        #expect(duck.splitted.query == #"BASE ON "cities"."id" IN ($1)"#)
        #expect(duck.splitted.values.map { String(describing: $0) } == ["1"])

        let postgres = query.prepare(.psql)
        #expect(postgres.plain == #"BASE ON "cities"."id" IN (1)"#)
        #expect(postgres.splitted.query == #"BASE ON "cities"."id" IN ($1)"#)
        #expect(postgres.splitted.values.map { String(describing: $0) } == ["1"])

        let mysql = query.prepare(.mysql)
        #expect(mysql.plain == "BASE ON cities.id IN (1)")
        #expect(mysql.splitted.query == "BASE ON cities.id IN (?)")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["1"])
    }

    @Test("Custom ON and USING owners propagate generic context without triggering Duck PIVOT policy")
    func customOwnerScopesRemainGenericUnderDuck() {
        let customOwner = SwifQLClauseOwner(namespace: "example", name: "region")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.on: customOwner, .using: customOwner],
            children: [SwifQLPartOperator.custom("BASE")]
        )
        let base = SwifQLableParts(parts: frame)
        let on = base.on(cities.column("id"))
        let using = base.using(cities.column("id"))

        #expect(on.structuralOwner(for: .on) == customOwner)
        #expect(using.structuralOwner(for: .using) == customOwner)
        #expect(on.prepare(.duck).plain == #"BASE ON "cities"."id""#)
        #expect(using.prepare(.duck).plain == #"BASE USING "cities"."id""#)

        let dialect = OwnerDerivedClauseScopeDialect(owner: customOwner)
        #expect(on.prepare(dialect).plain == "BASE ON custom-on-scope")
        #expect(using.prepare(dialect).plain == "BASE USING custom-using-scope")
    }

    @Test("Historical ON property and ordinary dialect output remain unchanged")
    func compatibility() {
        #expect(SwifQL.on.prepare(.psql).plain == "ON")

        let ordinary = SwifQL
            .select(cities.column("country"))
            .from(cities)
            .groupBy(cities.column("country"))
            .orderBy(.desc(cities.column("country")))

        #expect(
            ordinary.prepare(.psql).plain
                == #"SELECT "cities"."country" FROM "cities" GROUP BY "cities"."country" ORDER BY "cities"."country" DESC"#
        )
        #expect(
            ordinary.prepare(.mysql).plain
                == "SELECT cities.country FROM cities GROUP BY cities.country ORDER BY cities.country DESC"
        )
    }
}
