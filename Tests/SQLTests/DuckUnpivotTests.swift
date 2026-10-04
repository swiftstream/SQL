import Foundation
import Testing
@testable import SQL

private final class SimplifiedUnpivotScopeDialect: SQLDialect {
    override func tableName(_ value: String) -> String { "table" }

    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "qualified"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        context.contains(.simplifiedUnpivotOrderBy) ? "order-scope" : "qualified"
    }
}

private final class NestedUnpivotScopeDialect: SQLDialect {
    var labels: [String] = []

    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        labels.append("ordinary")
        return "ordinary"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        if context.contains(.simplifiedUnpivotOrderBy) {
            labels.append("unpivot-order")
            return "unpivot-order"
        }
        labels.append("ordinary")
        return "ordinary"
    }
}

private final class OwnerDerivedOrderByScopeDialect: SQLDialect {
    private let orderScope: SwifQLRenderScope

    init(owner: SwifQLClauseOwner) {
        self.orderScope = owner.renderScope(for: .orderBy)
        super.init()
    }

    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "qualified"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        context.contains(orderScope) ? "custom-order-scope" : "qualified"
    }
}

@Suite("Duck simplified UNPIVOT")
struct DuckUnpivotTests {
    private let sales = Path.Table("monthly_sales")

    private func base() -> SwifQLable {
        SwifQL.unpivot(sales)
            .on(sales.column("Jan"), sales.column("Feb"))
            .into(name: "month", value: "sales")
    }

    private func root(of query: SwifQLable) -> SwifQLStructuralFramePart {
        query.parts.first as! SwifQLStructuralFramePart
    }

    @Test("Basic simplified UNPIVOT and omitted INTO preserve native grammar")
    func basicAndOmittedInto() {
        let explicit = base()
        let omitted = SwifQL.unpivot(sales)
            .on(sales.column("Jan"), sales.column("Feb"))

        #expect(
            explicit.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales""#
        )
        #expect(
            omitted.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb""#
        )
    }

    @Test("Variadic ON coexists with the historical property and PIVOT IN overload")
    func onOverloadsRemainAvailable() {
        let property: SwifQLable = SwifQL.on
        let pivot = SwifQL.pivot(sales).on(sales.column("year"), in: 2020, 2021)
        let unpivot = SwifQL.unpivot(sales).on(sales.column("Jan"), sales.column("Feb"))

        #expect(property.prepare(.duck).plain == "ON")
        #expect(
            pivot.prepare(.duck).plain ==
                #"PIVOT "monthly_sales" ON "year" IN (2020, 2021)"#
        )
        #expect(
            unpivot.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb""#
        )
    }

    @Test("Prepared COLUMNS regex stays a normal Duck bind")
    func preparedRegex() {
        let pattern = "^(Jan|Jun)$"
        let prepared = SwifQL.unpivot(sales)
            .on(Fn.columns(regex: pattern))
            .into(name: "month", value: "sales")
            .prepare(.duck)

        #expect(
            prepared.plain ==
                #"UNPIVOT "monthly_sales" ON COLUMNS('^(Jan|Jun)$') INTO NAME "month" VALUE "sales""#
        )
        #expect(
            prepared.splitted.query ==
                #"UNPIVOT "monthly_sales" ON COLUMNS($1) INTO NAME "month" VALUE "sales""#
        )
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? String == pattern)
    }

    @Test("Single-column expressions stay distinct from the native two-column negative boundary")
    func expressionBoundaries() {
        let singleColumn = |(sales.column("Jan") + 1)|
        let twoColumns = |(sales.column("Jan") + sales.column("Feb"))|
        let singleQuery = SwifQL.unpivot(sales)
            .on(singleColumn)
            .into(name: "name", value: "value")
        let twoColumnQuery = SwifQL.unpivot(sales)
            .on(twoColumns)
            .into(name: "name", value: "value")

        #expect(
            singleQuery.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON ("monthly_sales"."Jan" + 1) INTO NAME "name" VALUE "value""#
        )
        #expect(
            twoColumnQuery.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON ("monthly_sales"."Jan" + "monthly_sales"."Feb") INTO NAME "name" VALUE "value""#
        )
    }

    @Test("Existing COLUMNS star, exclusion, and structural names compose unchanged")
    func columnsVariants() {
        let star = SwifQL.unpivot(sales)
            .on(Fn.columns(SwifQL.asterisk))
        let excluded = SwifQL.unpivot(sales)
            .on(Fn.columns(SwifQL.asterisk.exclude("empid", "dept")))
        let names = SwifQL.unpivot(sales)
            .on(Fn.columns(names: "Jan", "Feb"))

        #expect(star.prepare(.duck).plain == #"UNPIVOT "monthly_sales" ON COLUMNS(*)"#)
        #expect(
            excluded.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON COLUMNS(* EXCLUDE ("empid", "dept"))"#
        )
        #expect(
            names.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON COLUMNS(['Jan', 'Feb'])"#
        )
    }

    @Test("Shared variadic ON and structural parts remain mechanical in established dialects")
    func establishedDialectCompatibility() {
        let query = base()

        #expect(
            query.prepare(.psql).plain ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales""#
        )
        #expect(
            query.prepare(.mysql).plain ==
                "UNPIVOT monthly_sales ON monthly_sales.Jan, monthly_sales.Feb INTO NAME month VALUE sales"
        )
    }

    @Test("Grouped column sets preserve members, aliases, and parentheses")
    func groupedColumnSets() {
        let first = UnpivotColumnSet(
            sales.column("Jan"),
            sales.column("Feb"),
            sales.column("Mar"),
            as: "q1"
        )
        let second = UnpivotColumnSet(
            sales.column("Apr"),
            sales.column("May"),
            sales.column("Jun")
        )
        let query = SwifQL.unpivot(sales)
            .on(first, second)
            .into(name: "quarter", values: "v1", "v2", "v3")

        #expect(first.columns.count == 3)
        #expect(first.alias == "q1")
        #expect(second.alias == nil)
        #expect(
            query.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON ("monthly_sales"."Jan", "monthly_sales"."Feb", "monthly_sales"."Mar") as "q1", ("monthly_sales"."Apr", "monthly_sales"."May", "monthly_sales"."Jun") INTO NAME "quarter" VALUE "v1", "v2", "v3""#
        )
    }

    @Test("Grouped width mismatch remains visible instead of being rewritten")
    func groupedWidthMismatchBoundary() {
        let grouped = UnpivotColumnSet(
            sales.column("Jan"),
            sales.column("Feb"),
            sales.column("Mar"),
            as: "q1"
        )
        let query = SwifQL.unpivot(sales)
            .on(grouped)
            .into(name: "quarter", values: "v1", "v2")

        #expect(
            query.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON ("monthly_sales"."Jan", "monthly_sales"."Feb", "monthly_sales"."Mar") as "q1" INTO NAME "quarter" VALUE "v1", "v2""#
        )
    }

    @Test("INTO identifiers are structural and remain bind-free when quoted")
    func intoIdentifiers() {
        let query = SwifQL.unpivot(Path.Table("special_data"))
            .on(Path.Column("select"), Path.Column("имя"), Path.Column("a\"b"))
            .into(name: "ключ", values: "значение", "a\"b")
        let prepared = query.prepare(.duck)

        #expect(
            prepared.plain ==
                #"UNPIVOT "special_data" ON "select", "имя", "a""b" INTO NAME "ключ" VALUE "значение", "a""b""#
        )
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("Only simplified UNPIVOT ORDER BY receives its bounded owner scope")
    func orderByOwnerAndScope() {
        let query = base().orderBy(.asc(sales.column("month")))
        let limited = query.limit(2)

        #expect(query.structuralOwner(for: .orderBy) == .simplifiedUnpivot)
        #expect(
            query.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales" ORDER BY "month" ASC"#
        )
        #expect(
            query.prepare(SimplifiedUnpivotScopeDialect()).plain ==
                "UNPIVOT table ON qualified, qualified INTO NAME month VALUE sales ORDER BY order-scope ASC"
        )

        let orderByPart = root(of: query).children.compactMap { $0 as? SwifQLOrderByPart }.first
        #expect(orderByPart?.owner == .simplifiedUnpivot)
        #expect(
            limited.prepare(.duck).plain ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales" ORDER BY "month" ASC LIMIT 2"#
        )
        #expect(
            limited.prepare(.duck).splitted.query ==
                #"UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales" ORDER BY "month" ASC LIMIT $1"#
        )
        #expect(limited.prepare(.duck).splitted.values.map { $0 as? Int } == [2])
    }

    @Test("Custom ORDER BY owner propagates generic context without selecting Duck simplified-UNPIVOT policy")
    func customOrderByOwnerDoesNotSelectSimplifiedUnpivotPolicy() {
        let customOwner = SwifQLClauseOwner(namespace: "example", name: "region")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            owners: [.orderBy: customOwner],
            children: [SwifQLPartOperator.custom("BASE")]
        )
        let query = SwifQLableParts(parts: frame)
            .orderBy(.asc(sales.column("month")))

        #expect(query.structuralOwner(for: .orderBy) == customOwner)
        #expect(
            query.prepare(.duck).plain ==
                #"BASE ORDER BY "monthly_sales"."month" ASC"#
        )
        #expect(
            query.prepare(OwnerDerivedOrderByScopeDialect(owner: customOwner)).plain ==
                "BASE ORDER BY custom-order-scope ASC"
        )
    }

    @Test("The owner is value-semantic through copied stages and nested ordinary SQL")
    func ownershipIsolation() {
        let pivot = SwifQL.pivot(sales).on(sales.column("year"), in: 2020)
        let unpivot = SwifQLableParts(parts: base().parts)
        let copied = SwifQLableParts(parts: unpivot.orderBy(.desc(sales.column("month"))).parts)
        let ordinary = SwifQL
            .select(sales.column("month"))
            .from(sales)
            .orderBy(.asc(sales.column("month")))

        #expect(copied.structuralOwner(for: .orderBy) == .simplifiedUnpivot)
        #expect(pivot.structuralOwner(for: .on) == .simplifiedPivot)
        #expect(
            ordinary.prepare(.duck).plain ==
                #"SELECT "monthly_sales"."month" FROM "monthly_sales" ORDER BY "monthly_sales"."month" ASC"#
        )
    }

    @Test("Nested simplified UNPIVOT ownership does not leak to outer clauses")
    func nestedOwnershipIsolation() {
        let nested = base().orderBy(.asc(sales.column("month")))
        let outerOrder = SwifQL.select(nested).orderBy(.asc(sales.column("month")))
        let orderDialect = NestedUnpivotScopeDialect()
        _ = outerOrder.prepare(orderDialect)

        #expect(orderDialect.labels.contains("unpivot-order"))
        #expect(orderDialect.labels.last == "ordinary")

        let outerOn = SwifQL.select(nested).on(sales.column("id"))
        let onDialect = NestedUnpivotScopeDialect()
        _ = outerOn.prepare(onDialect)
        #expect(onDialect.labels.last == "ordinary")
    }

    @Test("Nested simplified-UNPIVOT ORDER BY policy does not leak to outer Duck ORDER BY")
    func nestedOrderByDoesNotLeakUnderDuck() {
        let nested = base().orderBy(.asc(sales.column("month")))
        let outerOrder = SwifQL.select(nested).orderBy(.desc(sales.column("month")))

        #expect(
            outerOrder.prepare(.duck).plain ==
                #"SELECT UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales" ORDER BY "month" ASC ORDER BY "monthly_sales"."month" DESC"#
        )
    }

    @Test("Simplified UNPIVOT is parenthesized when used as a downstream source")
    func downstreamParentheses() {
        let query = base()
        let unparenthesized = SwifQL
            .select(Path.Column("month"))
            .from(query)
        let parenthesized = SwifQL
            .select(Path.Column("month"))
            .from(|(query)|)

        #expect(
            unparenthesized.prepare(.duck).plain ==
                #"SELECT "month" FROM UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales""#
        )
        #expect(
            parenthesized.prepare(.duck).plain ==
                #"SELECT "month" FROM (UNPIVOT "monthly_sales" ON "monthly_sales"."Jan", "monthly_sales"."Feb" INTO NAME "month" VALUE "sales")"#
        )
    }

    @Test("Public identity is distinct from PIVOT and has no simplified ON scope")
    func publicIdentityBoundary() {
        #expect(SwifQLClauseOwner.simplifiedUnpivot.namespace == "swifql")
        #expect(SwifQLClauseOwner.simplifiedUnpivot.name == "simplifiedUnpivot")
        #expect(SwifQLClauseOwner.simplifiedUnpivot != .simplifiedPivot)
        #expect(
            SwifQLRenderScope.simplifiedUnpivotOrderBy ==
                SwifQLClauseOwner.simplifiedUnpivot.renderScope(for: .orderBy)
        )
        #expect(SwifQLClauseOwner.simplifiedUnpivot.renderScope(for: .on) != .simplifiedUnpivotOrderBy)
        #expect(SwifQLRenderScope.simplifiedUnpivotOrderBy != .simplifiedPivotOrderBy)
    }
}
