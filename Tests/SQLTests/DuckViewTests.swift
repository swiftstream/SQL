import Testing
@testable import SQL

@Suite("Duck direct view DDL")
struct DuckViewTests: SwifQLTests {
    private func viewSource(on prefix: SwifQLable) -> SwifQLable {
        let events = Path.Table("events")
        return prefix.select(events.column("id"), events.column("label")).from(events)
    }

    @Test("CREATE VIEW and OR REPLACE replacement columns use direct composition")
    func createAndReplace() {
        let create = viewSource(
            on: SwifQL.create.view[any: Path.Identifier("report")].as
        )
        let replace = viewSource(
            on: SwifQL.create.or.replace.view[any: Path.Identifier("report")]
            .fields("event_id", "event_label")
            .as
        )

        #expect(
            create.prepare(.duck).plain ==
                #"CREATE VIEW "report" as SELECT "events"."id", "events"."label" FROM "events""#
        )
        #expect(
            replace.prepare(.duck).plain ==
                #"CREATE OR REPLACE VIEW "report" ("event_id", "event_label") as SELECT "events"."id", "events"."label" FROM "events""#
        )
        #expect(create.prepare(.duck).splitted.values.isEmpty)
        #expect(replace.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("TEMP and TEMPORARY are independent atomic view keywords")
    func temporaryViews() {
        let temp = viewSource(
            on: SwifQL.create.temp.view[any: Path.Identifier("scratch")].as
        )
        let temporary = viewSource(
            on: SwifQL.create.temporary.view[any: Path.Identifier("scratch_long")].as
        )

        #expect(
            temp.prepare(.duck).plain ==
                #"CREATE TEMP VIEW "scratch" as SELECT "events"."id", "events"."label" FROM "events""#
        )
        #expect(
            temporary.prepare(.duck).plain ==
                #"CREATE TEMPORARY VIEW "scratch_long" as SELECT "events"."id", "events"."label" FROM "events""#
        )
    }

    @Test("ALTER VIEW rename and DROP VIEW modifiers stay ordinary atoms")
    func alterAndDrop() {
        let rename = SwifQL.alter.view[any: Path.Identifier("report")]
            .rename
            .to[any: Path.Identifier("report_v2")]
        let drop = SwifQL.drop.view.if.exists[any: Path.Identifier("report_v2")]
        let dropRestrict = SwifQL.drop.view[any: Path.Identifier("report_v2")].restrict
        let dropCascade = SwifQL.drop.view[any: Path.Identifier("report_v2")].cascade

        #expect(rename.prepare(.duck).plain == #"ALTER VIEW "report" RENAME TO "report_v2""#)
        #expect(drop.prepare(.duck).plain == #"DROP VIEW IF EXISTS "report_v2""#)
        #expect(dropRestrict.prepare(.duck).plain == #"DROP VIEW "report_v2" RESTRICT"#)
        #expect(dropCascade.prepare(.duck).plain == #"DROP VIEW "report_v2" CASCADE"#)
    }

    @Test("Qualified view identifiers preserve catalog/schema ownership")
    func qualifiedNames() {
        let schemaView = SwifQL.create.view[any: Path.Identifier(schema: "analytics", name: "report")]
        let catalogView = SwifQL.create.view[
            any: Path.Identifier(catalog: "memory", schema: "analytics", name: "report")
        ]

        #expect(schemaView.prepare(.duck).plain == #"CREATE VIEW "analytics"."report""#)
        #expect(catalogView.prepare(.duck).plain == #"CREATE VIEW "memory"."analytics"."report""#)
    }

    @Test("View source values keep ordinary bind mechanics at the child boundary")
    func preparedValues() {
        let query = SwifQL.create.view[any: Path.Identifier("runtime")]
            .as
            .select("runtime")
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == #"CREATE VIEW "runtime" as SELECT 'runtime'"#)
        #expect(prepared.splitted.query == #"CREATE VIEW "runtime" as SELECT $1"#)
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? String == "runtime")
    }

    @Test("Copied, erased, and helper-composed view source stays invariant")
    func compositionInvariance() {
        let query = viewSource(
            on: SwifQL.create.view[any: Path.Identifier("report")].as
        )
        let copied = SwifQLableParts(parts: query.parts)
        let erased: SwifQLable = copied
        let helperParts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.custom("TAIL")
        ]
        let helper = SwifQLableParts(parts: helperParts)

        #expect(copied.prepare(.duck).plain == query.prepare(.duck).plain)
        #expect(erased.prepare(.duck).plain == query.prepare(.duck).plain)
        #expect((query ~ helper).prepare(.duck).plain.hasSuffix(" TAIL"))
    }
}
