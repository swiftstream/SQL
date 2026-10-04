import Foundation
import Testing
@testable import SQL

private final class StructuralScopeDialect: SQLDialect {
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

private final class OwnerScopeDialect: SQLDialect {
    private let groupScope: SwifQLRenderScope
    private let orderScope: SwifQLRenderScope

    init(owner: SwifQLClauseOwner) {
        self.groupScope = owner.renderScope(for: .groupBy)
        self.orderScope = owner.renderScope(for: .orderBy)
        super.init()
    }

    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "plain"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        if context.contains(groupScope) {
            return "group-scoped"
        }
        if context.contains(orderScope) {
            return "order-scoped"
        }
        return "plain"
    }
}

@Suite("Structural clause ownership")
struct StructuralClauseOwnershipTests {
    private let owner = SwifQLClauseOwner(namespace: "example", name: "region")

    private func root(of query: SwifQLable) -> SwifQLStructuralFramePart {
        query.parts.first as! SwifQLStructuralFramePart
    }

    private func groupByPart(in query: SwifQLable) -> SwifQLGroupByPart {
        root(of: query).children.compactMap { $0 as? SwifQLGroupByPart }.first!
    }

    private func orderByPart(in query: SwifQLable) -> SwifQLOrderByPart {
        root(of: query).children.compactMap { $0 as? SwifQLOrderByPart }.first!
    }

    @Test("Clause-owner render scopes preserve collision-free identity")
    func collisionFreeRenderScopeIdentity() {
        let kind = SwifQLClauseKind(namespace: "d", name: "e")
        let firstOwner = SwifQLClauseOwner(namespace: "a.b", name: "c")
        let secondOwner = SwifQLClauseOwner(namespace: "a", name: "b.c")
        let firstScope = firstOwner.renderScope(for: kind)
        let secondScope = secondOwner.renderScope(for: kind)
        let context = SwifQLRenderContext(scopes: [firstScope])

        #expect(firstScope != secondScope)
        #expect(context.contains(firstScope))
        #expect(context.contains(secondScope) == false)
        #expect(firstScope == firstOwner.renderScope(for: kind))
        #expect(Set([firstScope, firstOwner.renderScope(for: kind)]).count == 1)
        #expect(
            firstScope != SwifQLClauseOwner(namespace: "a.b", name: "different")
                .renderScope(for: kind)
        )
        #expect(
            firstScope != firstOwner.renderScope(
                for: SwifQLClauseKind(namespace: "d.e", name: "different")
            )
        )
        #expect(firstScope.namespace == "swifql.clause-owner")
        #expect(firstScope.name == "a.b.c.d.e")
        #expect(firstScope.identityComponents == [
            .init(namespace: "a.b", name: "c"),
            .init(namespace: "d", name: "e")
        ])
    }

    @Test("Simple named render scopes retain namespaced identity")
    func namedRenderScopeCompatibility() {
        let reconstructed = SwifQLRenderScope(namespace: "swifql", name: "starPattern")

        #expect(SwifQLRenderScope.starPattern == reconstructed)
        #expect(reconstructed.namespace == "swifql")
        #expect(reconstructed.name == "starPattern")
        #expect(reconstructed.identityComponents.isEmpty)
    }

    @Test("Ordinary GROUP BY and ORDER BY keep nil ownership")
    func ordinaryOwnershipAndSQL() {
        let table = Path.Table("users")
        let id = table.column("id")
        let name = table.column("name")
        let query = SwifQL
            .select(id)
            .from(table)
            .groupBy(name)
            .orderBy(.desc(id))

        #expect(groupByPart(in: query).owner == nil)
        #expect(orderByPart(in: query).owner == nil)
        #expect(query.prepare(.psql).plain == #"SELECT "users"."id" FROM "users" GROUP BY "users"."name" ORDER BY "users"."id" DESC"#)
        #expect(query.prepare(.mysql).plain == "SELECT users.id FROM users GROUP BY users.name ORDER BY users.id DESC")
    }

    @Test("Current root owner is selected and persists in public clause parts")
    func syntheticOwnerPersistence() {
        let table = Path.Table("events")
        let id = table.column("id")
        let country = table.column("country")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner, .orderBy: owner],
            children: [
                SwifQLPartOperator.select,
                SwifQLPartOperator.space,
                id.parts[0]
            ]
        )
        let base = SwifQLableParts(parts: frame)
        let grouped = base.groupBy(country)
        let query = grouped.orderBy(.desc(country))

        #expect(groupByPart(in: query).owner == owner)
        #expect(orderByPart(in: query).owner == owner)
        #expect(groupByPart(in: query).fields.count == 1)
        #expect(orderByPart(in: query).items.count == 1)
        #expect(query.structuralOwner(for: .groupBy) == owner)
        #expect(query.structuralOwner(for: .orderBy) == owner)
    }

    @Test("Persisted clause owners drive bounded GROUP BY and ORDER BY rendering")
    func ownerSensitiveRendering() {
        let table = Path.Table("events")
        let groupPath = table.column("group_value")
        let orderPath = table.column("order_value")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner, .orderBy: owner]
        )
        let owned = SwifQLableParts(parts: frame)
            .groupBy(groupPath)
            .orderBy(.asc(orderPath))

        #expect(
            owned.prepare(OwnerScopeDialect(owner: owner)).plain
                == "GROUP BY group-scoped ORDER BY order-scoped ASC"
        )

        let neutralPath = table.column("neutral")
        let ordinary = SwifQL
            .select(neutralPath)
            .groupBy(neutralPath)
            .orderBy(.asc(neutralPath))
        #expect(
            ordinary.prepare(OwnerScopeDialect(owner: owner)).plain
                == "SELECT plain GROUP BY plain ORDER BY plain ASC"
        )
    }

    @Test("Copied parts preserve frames and selected clause ownership")
    func copiedPartsPreserveOwnership() {
        let table = Path.Table("events")
        let country = table.column("country")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner, .orderBy: owner]
        )
        let base = SwifQLableParts(parts: frame)
        let copiedBeforeClauses = SwifQLableParts(parts: base.parts)
        let copiedAfterGroup = SwifQLableParts(parts: copiedBeforeClauses.groupBy(country).parts)
        let query = copiedAfterGroup.orderBy(.asc(country))
        let copied = SwifQLableParts(parts: query.parts)

        #expect(groupByPart(in: copied).owner == owner)
        #expect(orderByPart(in: copied).owner == owner)
        #expect(groupByPart(in: copied).fields.count == 1)
        #expect(orderByPart(in: copied).items.count == 1)
        #expect(copied.structuralOwner(for: .groupBy) == owner)
        #expect(copied.structuralOwner(for: .orderBy) == owner)
        #expect(
            groupByPart(in: copied).owner?.renderScope(for: .groupBy)
                == owner.renderScope(for: .groupBy)
        )
        #expect(
            orderByPart(in: copied).owner?.renderScope(for: .orderBy)
                == owner.renderScope(for: .orderBy)
        )
    }

    @Test("Nested frames isolate render context while sharing preparation")
    func nestedFrameContextIsolation() {
        let scope = SwifQLRenderScope(namespace: "example", name: "outer")
        let outerExpression = Path.Table("outer").column("value").scoped(scope)
        let nestedFrame = SwifQLStructuralFramePart(
            region: .statement,
            children: Path.Table("inner").column("value").parts
        )
        let rootFrame = SwifQLStructuralFramePart(
            region: .statement,
            children: outerExpression.parts + [nestedFrame]
        )
        let query = SwifQLableParts(parts: rootFrame)

        #expect(query.prepare(StructuralScopeDialect(observedScope: scope)).plain == "scopedplain")
    }

    @Test("Nested frames and owner-sensitive clauses preserve depth-first bind order")
    func nestedFrameBindOrder() {
        let nestedFrame = SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartUnsafeValue("insideNested"),
                SwifQLPartOperator.space,
                SwifQLPartUnsafeValue("nestedWhere")
            ]
        )
        let group = SwifQLGroupByPart(
            owner: owner,
            fields: [[SwifQLPartUnsafeValue("ownedClause")]]
        )
        let rootFrame = SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartUnsafeValue("before"),
                SwifQLPartOperator.space,
                nestedFrame,
                SwifQLPartOperator.space,
                group,
                SwifQLPartOperator.space,
                SwifQLPartUnsafeValue("after")
            ]
        )
        let query = SwifQLableParts(parts: rootFrame)

        #expect(query.prepare(.psql).splitted.values.map { String(describing: $0) } == [
            "before", "insideNested", "nestedWhere", "ownedClause", "after"
        ])
    }

    @Test("Nested frame ownership does not affect an outer clause")
    func nestedFrameOwnershipIsolation() {
        let nestedOwner = SwifQLClauseOwner(namespace: "nested", name: "region")
        let nested = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: nestedOwner],
            children: []
        )
        let outer = SwifQLStructuralFramePart(
            region: .statement,
            children: [nested]
        )
        let query = SwifQLableParts(parts: outer).groupBy(Path.Table("events").column("country"))

        #expect(groupByPart(in: query).owner == nil)
    }

    @Test("Arbitrary GROUP BY expressions remain composable")
    func arbitraryGroupByExpression() {
        let table = Path.Table("users")
        let expression = table.column("id") + 1
        let query = SwifQL.select(expression).from(table).groupBy(expression)

        #expect(query.prepare(.psql).plain == #"SELECT "users"."id" + 1 FROM "users" GROUP BY "users"."id" + 1"#)
    }

    @Test("Generic owner merge replaces selected keys and preserves unrelated mappings")
    func genericOwnerMerge() {
        let replacement = SwifQLClauseOwner(namespace: "example", name: "replacement")
        let unrelatedKind = SwifQLClauseKind(namespace: "example", name: "unrelated")
        let unrelatedOwner = SwifQLClauseOwner(namespace: "example", name: "unrelated-owner")
        let nestedOwner = SwifQLClauseOwner(namespace: "nested", name: "opaque")
        let nested = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: nestedOwner]
        )
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [
                .groupBy: owner,
                .orderBy: owner,
                unrelatedKind: unrelatedOwner
            ],
            children: [nested]
        )
        let base = SwifQLableParts(parts: frame)
        let merged = _SQLStructuralComposition.append(
            base,
            parts: [SwifQLPartOperator.space, SwifQLPartOperator.custom("TAIL")],
            owners: [.groupBy: replacement]
        )

        let mergedRoot = root(of: merged)
        #expect(mergedRoot.owner(for: .groupBy) == replacement)
        #expect(mergedRoot.owner(for: .orderBy) == owner)
        #expect(mergedRoot.owner(for: unrelatedKind) == unrelatedOwner)
        #expect((mergedRoot.children.first as? SwifQLStructuralFramePart)?.owner(for: .groupBy) == nestedOwner)

        let unframed = SwifQLableParts(parts: SwifQLPartOperator.custom("BASE"))
        let ownerSet = _SQLStructuralComposition.append(
            unframed,
            parts: [SwifQLPartOperator.space, SwifQLPartOperator.custom("TAIL")],
            owners: [.groupBy: replacement]
        )
        #expect(ownerSet.structuralOwner(for: .groupBy) == replacement)
        #expect(ownerSet.prepare(.psql).plain == "BASE TAIL")

        let ordinaryContinuation = _SQLStructuralComposition.append(
            unframed,
            parts: [SwifQLPartOperator.space, SwifQLPartOperator.custom("TAIL")]
        )
        #expect(ordinaryContinuation.parts.first is SwifQLStructuralFramePart == false)
        #expect(ordinaryContinuation.prepare(.psql).plain == "BASE TAIL")
    }
}
