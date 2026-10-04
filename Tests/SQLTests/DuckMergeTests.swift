import Testing
@testable import SQL

private final class MergeSemanticDialect: SQLDialect {
    override func alias(_ value: String) -> String { "alias(\(value))" }
    override func column(_ value: String) -> String { "column(\(value))" }
}

private func returningPreservingExpressionParts(
    _ base: SwifQLable,
    _ expressions: SwifQLable...
) -> SwifQLable {
    var parts: [SwifQLPart] = [
        SwifQLPartOperator.space,
        SwifQLPartOperator.returning,
        SwifQLPartOperator.space
    ]
    for (index, expression) in expressions.enumerated() {
        if index > 0 {
            parts.append(o: .comma, .space)
        }
        parts.append(contentsOf: expression.parts)
    }
    return base.structurallyAppending(SwifQLableParts(parts: parts))
}

@Suite("Duck MERGE")
struct DuckMergeTests: SwifQLTests {
    private let target = Path.Table("merge_target")
    private let source = Path.Table("merge_source")

    private func base() -> SwifQLable {
        SwifQL.merge(
            into: target,
            using: source,
            on: target.column("id") == source.column("id")
        )
    }

    @Test("One-shot and incremental MERGE composition are identical")
    func compositionInvariance() {
        let oneShot = base()
        let incremental = SwifQL
            .merge(into: target)
            .using(source)
            .on(target.column("id") == source.column("id"))

        var erased: SwifQLable = SwifQL.merge(into: target)
        erased = erased.using(source)
        erased = erased.on(target.column("id") == source.column("id"))
        let copied = SwifQLableParts(parts: erased.parts)

        check(
            oneShot,
            .duck(#"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id""#),
            .psql(#"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id""#),
            .mysql("MERGE INTO merge_target USING merge_source ON merge_target.id = merge_source.id")
        )
        #expect(oneShot.prepare(.duck).plain == incremental.prepare(.duck).plain)
        #expect(oneShot.prepare(.duck).splitted.query == incremental.prepare(.duck).splitted.query)
        #expect(copied.prepare(.duck).plain == oneShot.prepare(.duck).plain)
        #expect(copied.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("String targets remain structural and the generic ON and USING overloads stay available")
    func overloadBoundaries() {
        let stringTarget = SwifQL.merge(
            into: "merge_target",
            using: source,
            on: Path.Column("id") == source.column("id")
        )
        #expect(
            stringTarget.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "id" = "merge_source"."id""#
        )
        #expect(stringTarget.prepare(.duck).splitted.values.isEmpty)

        let oldOn: SwifQLable = SwifQL.on
        #expect(oldOn.prepare(.duck).plain == "ON")

        let pivot = SwifQL
            .pivot(target)
            .on(target.column("year"), in: 2020)
            .using(Fn.sum(target.column("amount")))
        #expect(
            pivot.prepare(.duck).plain ==
                #"PIVOT "merge_target" ON "year" IN (2020) USING sum("amount")"#
        )

        let deleteUsing = SwifQL.delete(from: target).using(source)
        #expect(
            deleteUsing.prepare(.duck).plain ==
                #"DELETE FROM "merge_target" USING "merge_source""#
        )
    }

    @Test("USING shorthand is structural, quoted, and qualification-safe")
    func usingShorthand() {
        let single = SwifQL
            .merge(into: target)
            .using(source)
            .using(columns: target.column("id"))
        let multiple = SwifQL
            .merge(into: target)
            .using(source)
            .using(columns: Path.Column("id"), Path.Column("tenant"))
        let quoted = SwifQL
            .merge(into: target)
            .using(source)
            .using(columns: "select", "имя", "a\"b")

        #expect(
            single.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" USING ("id")"#
        )
        #expect(
            multiple.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" USING ("id", "tenant")"#
        )
        #expect(
            quoted.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" USING ("select", "имя", "a""b")"#
        )
        #expect(single.prepare(.duck).splitted.values.isEmpty)
        #expect(multiple.prepare(.duck).splitted.values.isEmpty)
        #expect(quoted.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("USING shorthand dispatches through column semantics")
    func usingShorthandUsesColumnHook() {
        let dialect = MergeSemanticDialect()
        let query = SwifQL
            .merge(into: Path.Table("merge_target"))
            .using(Path.Table("merge_source"))
            .using(columns: Path.Column("id"), Path.Column("tenant"))

        #expect(
            TableAlias("alias_marker").prepare(dialect).plain == "alias(alias_marker)"
        )
        #expect(
            SwifQLableParts(parts: [SwifQLPartColumn("column_marker")])
                .prepare(dialect)
                .plain == "column(column_marker)"
        )
        #expect(
            query.prepare(dialect).plain ==
                "MERGE INTO merge_target USING merge_source USING (column(id), column(tenant))"
        )
    }

    @Test("Branch vocabulary reuses established DML actions and preserves order")
    func branchesAndActions() {
        let update = base()
            .when.matched
            .then
            .update
            .set(Path.Column("value") == source.column("value"))
        let conditionalUpdate = base()
            .when.matched.and(target.column("kind") == "apply")
            .then
            .update
            .set(Path.Column("value") == "updated")
        let delete = base()
            .when.matched.and(target.column("kind") == "expired")
            .then
            .delete
        let insert = base()
            .when.not.matched
            .then
            .insert
        let nameAlignedInsert = base()
            .when.not.matched.by.target
            .then
            .insert
            .by.name
        let insertFields = base()
            .when.not.matched.and(target.column("kind") == "new")
            .then
            .insert
            .fields("id", "value", "kind")
            .values
            .values(source.column("id"), source.column("value"), source.column("kind"))
        let sourceDelete = base()
            .when.not.matched.by.source
            .then
            .delete
        let sourceUpdate = base()
            .when.not.matched.by.source.and(target.column("kind") == "expired")
            .then
            .update
            .set(Path.Column("value") == "expired")

        check(
            update,
            .duck(#"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED THEN UPDATE SET "value" = "merge_source"."value""#),
            .mysql("MERGE INTO merge_target USING merge_source ON merge_target.id = merge_source.id WHEN MATCHED THEN UPDATE SET value = merge_source.value")
        )
        #expect(
            conditionalUpdate.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED AND "merge_target"."kind" = 'apply' THEN UPDATE SET "value" = 'updated'"#
        )
        #expect(
            delete.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED AND "merge_target"."kind" = 'expired' THEN DELETE"#
        )
        #expect(
            insert.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED THEN INSERT"#
        )
        #expect(
            nameAlignedInsert.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED BY TARGET THEN INSERT BY NAME"#
        )
        #expect(
            insertFields.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED AND "merge_target"."kind" = 'new' THEN INSERT ("id", "value", "kind") VALUES ("merge_source"."id", "merge_source"."value", "merge_source"."kind")"#
        )
        #expect(
            sourceDelete.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED BY SOURCE THEN DELETE"#
        )
        #expect(
            sourceUpdate.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED BY SOURCE AND "merge_target"."kind" = 'expired' THEN UPDATE SET "value" = 'expired'"#
        )

        let ordered = base()
            .when.matched
            .then
            .update
            .set(Path.Column("value") == "first")
            .when.not.matched
            .then
            .insert
        let orderedSQL = ordered.prepare(.duck).plain
        #expect(orderedSQL.range(of: "WHEN MATCHED")!.lowerBound < orderedSQL.range(of: "WHEN NOT MATCHED")!.lowerBound)
    }

    @Test("Bare merge_action and RETURNING compose without a function remap")
    func returning() {
        let query = base()
            .when.matched
            .then
            .update
            .set(Path.Column("value") == "updated")
            .returning[items: SwifQL.mergeAction, SwifQL.asterisk]

        #expect(SwifQL.mergeAction.prepare(.duck).plain == "merge_action")
        #expect(!SwifQL.mergeAction.prepare(.duck).plain.contains("("))
        #expect(
            query.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED THEN UPDATE SET "value" = 'updated' RETURNING merge_action, *"#
        )
        #expect(
            query.prepare(.mysql).plain ==
                "MERGE INTO merge_target USING merge_source ON merge_target.id = merge_source.id WHEN MATCHED THEN UPDATE SET value = 'updated' RETURNING merge_action, *"
        )
    }

    @Test("MERGE preserves the normal left-to-right bind stream")
    func bindOrder() {
        let query = base()
            .when.matched.and(target.column("kind") == "apply")
            .then
            .update
            .set(Path.Column("value") == "updated")
            .when.not.matched.and(target.column("kind") == "new")
            .then
            .insert
            .fields("id", "value")
            .values
            .values(2, "inserted")
            .returning[items: SwifQL.mergeAction, Path.Column("id")]
        let prepared = query.prepare(.duck)
        let expectedPlain = #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED AND "merge_target"."kind" = 'apply' THEN UPDATE SET "value" = 'updated' WHEN NOT MATCHED AND "merge_target"."kind" = 'new' THEN INSERT ("id", "value") VALUES (2, 'inserted') RETURNING merge_action, "id""#
        let expectedQuery = #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED AND "merge_target"."kind" = $1 THEN UPDATE SET "value" = $2 WHEN NOT MATCHED AND "merge_target"."kind" = $3 THEN INSERT ("id", "value") VALUES ($4, $5) RETURNING merge_action, "id""#

        #expect(prepared.plain == expectedPlain)
        #expect(prepared.splitted.query == expectedQuery)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["apply", "updated", "new", "2", "inserted"])
        #expect(prepared.splitted.values.count == 5)
    }

    @Test("Native-invalid branch and RETURNING siblings stay mechanically expressible")
    func nativeNegativeSiblingsStayMechanical() {
        let bySourceInsert = base()
            .when.not.matched.by.source
            .then
            .insert
        let byTargetUpdate = base()
            .when.not.matched.by.target
            .then
            .update
            .set(Path.Column("value") == "mechanical")
        let byTargetDelete = base()
            .when.not.matched.by.target
            .then
            .delete
        let notMatchedDelete = base()
            .when.not.matched
            .then
            .delete
        let returningBase = base()
            .when.matched
            .then
            .update
            .set(Path.Column("value") == source.column("value"))
        let targetQualifiedReturning = returningPreservingExpressionParts(
            returningBase,
            target.column("value")
        )
        let sourceQualifiedReturning = returningPreservingExpressionParts(
            returningBase,
            source.column("value")
        )
        let preparedReturning = base()
            .returning[items: "projection"]

        #expect(
            bySourceInsert.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED BY SOURCE THEN INSERT"#
        )
        #expect(
            byTargetUpdate.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED BY TARGET THEN UPDATE SET "value" = 'mechanical'"#
        )
        #expect(
            byTargetDelete.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED BY TARGET THEN DELETE"#
        )
        #expect(
            notMatchedDelete.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN NOT MATCHED THEN DELETE"#
        )
        #expect(
            targetQualifiedReturning.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED THEN UPDATE SET "value" = "merge_source"."value" RETURNING "merge_target"."value""#
        )
        #expect(
            sourceQualifiedReturning.prepare(.duck).plain ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" WHEN MATCHED THEN UPDATE SET "value" = "merge_source"."value" RETURNING "merge_source"."value""#
        )
        #expect(
            preparedReturning.prepare(.duck).splitted.query ==
                #"MERGE INTO "merge_target" USING "merge_source" ON "merge_target"."id" = "merge_source"."id" RETURNING $1"#
        )
        #expect(preparedReturning.prepare(.duck).splitted.values.count == 1)
    }

    @Test("Existing JOIN USING, UNPIVOT ON, and star/COLUMNS APIs remain unambiguous")
    func siblingOverloads() {
        let join = SwifQL
            .select(target.column("id"))
            .from(target)
            .join(source, using: "id")
        let unpivot = SwifQL
            .unpivot(target)
            .on(target.column("jan"), target.column("feb"))
        let columns = SwifQL.select(Fn.columns(SwifQL.asterisk))

        #expect(
            join.prepare(.duck).plain ==
                #"SELECT "merge_target"."id" FROM "merge_target" JOIN "merge_source" USING ("id")"#
        )
        #expect(
            unpivot.prepare(.duck).plain ==
                #"UNPIVOT "merge_target" ON "merge_target"."jan", "merge_target"."feb""#
        )
        #expect(columns.prepare(.duck).plain == "SELECT COLUMNS(*)")
    }
}
