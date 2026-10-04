import Testing
@testable import SQL

@Suite("Duck ordinary DML")
struct DuckDMLTests: SwifQLTests {
    private let events = Path.Table("events")
    private let source = Path.Table("event_source")

    private func insertValues(_ table: Path.Table) -> SwifQLable {
        SwifQL
            .insertInto(table, fields: "id", "name")
            .values
            .values(1, "one")
    }

    @Test("No-field INSERT and BY NAME preserve direct SQL composition")
    func insertRoots() {
        let noFields = SwifQL.insertInto(events)
        #expect(noFields.prepare(.duck).plain == #"INSERT INTO "events""#)
        #expect(noFields.prepare(.duck).splitted.values.isEmpty)

        let nameAligned = SwifQL
            .insertInto(events)
            .by.name
            .select(2 => "name", 1 => "id")
        let prepared = nameAligned.prepare(.duck)

        #expect(
            prepared.plain ==
                #"INSERT INTO "events" BY NAME SELECT 2 as "name", 1 as "id""#
        )
        #expect(
            prepared.splitted.query ==
                #"INSERT INTO "events" BY NAME SELECT $1 as "name", $2 as "id""#
        )
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["2", "1"])

        var erased: SwifQLable = SwifQL.insertInto(events)
        erased = erased.by.name
        erased = erased.select(2 => "name", 1 => "id")
        let copied = SwifQLableParts(parts: erased.parts)
        #expect(copied.prepare(.duck).plain == prepared.plain)
        #expect(copied.prepare(.duck).splitted.query == prepared.splitted.query)
    }

    @Test("INSERT VALUES and INSERT SELECT preserve row order and bind order")
    func insertSources() {
        let rows = SwifQL
            .insertInto(events, fields: "id", "name")
            .values
            .values(array: [1, "one"], [2, "two"])
        let rowsPrepared = rows.prepare(.duck)

        #expect(
            rowsPrepared.plain ==
                #"INSERT INTO "events" ("id", "name") VALUES (1, 'one'), (2, 'two')"#
        )
        #expect(
            rowsPrepared.splitted.query ==
                #"INSERT INTO "events" ("id", "name") VALUES ($1, $2), ($3, $4)"#
        )
        #expect(rowsPrepared.splitted.values.map { String(describing: $0) } == ["1", "one", "2", "two"])

        let select = SwifQL
            .insertInto(events, fields: "id", "name")
            .select(source.column("id"), source.column("name"))
            .from(source)
            .where(source.column("id") > 1)
        let selectPrepared = select.prepare(.duck)

        #expect(
            selectPrepared.plain ==
                #"INSERT INTO "events" ("id", "name") SELECT "event_source"."id", "event_source"."name" FROM "event_source" WHERE "event_source"."id" > 1"#
        )
        #expect(
            selectPrepared.splitted.query ==
                #"INSERT INTO "events" ("id", "name") SELECT "event_source"."id", "event_source"."name" FROM "event_source" WHERE "event_source"."id" > $1"#
        )
        #expect(selectPrepared.splitted.values.map { String(describing: $0) } == ["1"])
    }

    @Test("BY NAME remains an exact phrase beside the native VALUES negative")
    func nameAlignedValuesNeighborRemainsMechanical() {
        let query = SwifQL
            .insertInto(events)
            .by.name
            .values
            .values(1, 2)

        #expect(
            query.prepare(.duck).plain ==
                #"INSERT INTO "events" BY NAME VALUES (1, 2)"#
        )
    }

    @Test("OR IGNORE and OR REPLACE keep their exact SQL identities")
    func exactInsertConflictForms() {
        let ignore = SwifQL
            .insert.or.ignore.into[table: events]
            .values
            .values(1, "one")
        let ignoreWithFields = SwifQL
            .insert.or.ignore.into[table: events]
            .fields("id", "name")
            .values
            .values(1, "one")
        let replace = SwifQL
            .insert.or.replace.into[table: events]
            .values
            .values(1, "one")
        let replaceWithFields = SwifQL
            .insert.or.replace.into[table: events]
            .fields("id", "name")
            .values
            .values(1, "one")

        check(
            ignore,
            .duck(#"INSERT OR IGNORE INTO "events" VALUES (1, 'one')"#),
            .psql(#"INSERT OR IGNORE INTO "events" VALUES (1, 'one')"#),
            .mysql("INSERT OR IGNORE INTO events VALUES (1, 'one')")
        )
        check(
            replace,
            .duck(#"INSERT OR REPLACE INTO "events" VALUES (1, 'one')"#),
            .psql(#"INSERT OR REPLACE INTO "events" VALUES (1, 'one')"#),
            .mysql("INSERT OR REPLACE INTO events VALUES (1, 'one')")
        )
        #expect(
            ignoreWithFields.prepare(.duck).plain ==
                #"INSERT OR IGNORE INTO "events" ("id", "name") VALUES (1, 'one')"#
        )
        #expect(
            replaceWithFields.prepare(.duck).plain ==
                #"INSERT OR REPLACE INTO "events" ("id", "name") VALUES (1, 'one')"#
        )

        let prepared = replace.prepare(.duck).splitted
        #expect(prepared.query == #"INSERT OR REPLACE INTO "events" VALUES ($1, $2)"#)
        #expect(prepared.values.map { String(describing: $0) } == ["1", "one"])
    }

    @Test("String table targets stay structural across the complete DML family")
    func stringTableTargetsStayStructural() {
        let noFields = SwifQL.insertInto("events")
        let ignore = SwifQL.insert.or.ignore.into[table: "events"].values.values(1, "one")
        let ignoreWithFields = SwifQL
            .insert.or.ignore.into[table: "events"]
            .fields(["id", "name"])
            .values
            .values(2, "two")
        let replace = SwifQL.insert.or.replace.into[table: "events"].values.values(3, "three")
        let replaceWithFields = SwifQL
            .insert.or.replace.into[table: "events"]
            .fields(["id", "name"])
            .values
            .values(4, "four")
        let truncated = SwifQL.truncate("events")

        check(
            noFields,
            .duck(#"INSERT INTO "events""#),
            .psql(#"INSERT INTO "events""#),
            .mysql("INSERT INTO events")
        )
        check(
            ignore,
            .duck(#"INSERT OR IGNORE INTO "events" VALUES (1, 'one')"#),
            .psql(#"INSERT OR IGNORE INTO "events" VALUES (1, 'one')"#),
            .mysql("INSERT OR IGNORE INTO events VALUES (1, 'one')")
        )
        check(
            replace,
            .duck(#"INSERT OR REPLACE INTO "events" VALUES (3, 'three')"#),
            .psql(#"INSERT OR REPLACE INTO "events" VALUES (3, 'three')"#),
            .mysql("INSERT OR REPLACE INTO events VALUES (3, 'three')")
        )
        check(
            truncated,
            .duck(#"TRUNCATE "events""#),
            .psql(#"TRUNCATE "events""#),
            .mysql("TRUNCATE events")
        )

        #expect(
            ignoreWithFields.prepare(.duck).plain ==
                #"INSERT OR IGNORE INTO "events" ("id", "name") VALUES (2, 'two')"#
        )
        #expect(
            replaceWithFields.prepare(.duck).plain ==
                #"INSERT OR REPLACE INTO "events" ("id", "name") VALUES (4, 'four')"#
        )

        let prepared = ignore.prepare(.duck).splitted
        #expect(prepared.query == #"INSERT OR IGNORE INTO "events" VALUES ($1, $2)"#)
        #expect(prepared.values.map { String(describing: $0) } == ["1", "one"])
        #expect(prepared.values.count == 2)
        #expect(noFields.prepare(.duck).splitted.values.isEmpty)
        #expect(truncated.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Existing ON CONFLICT composition remains exact and bind-ordered")
    func conflictCompatibility() {
        let noTargetDoNothing = insertValues(events)
            .on
            .conflict
            .do
            .nothing
        let targetDoNothing = insertValues(events)
            .on
            .conflict(events.column("id"))
            .do
            .nothing
        let excluded = Path.Table("EXCLUDED")
        let assignments = (Path.Column("value") == excluded.column("value")) ~ (
            SwifQLableParts(parts: SwifQLPartOperator.comma, SwifQLPartOperator.space) ~
            (Path.Column("gate") == excluded.column("gate"))
        )
        let doUpdate = SwifQL
            .insertInto(Path.Table("conflict_actions"), fields: "id", "value", "gate")
            .values
            .values(1, "updated", 3)
            .on
            .conflict(Path.Table("conflict_actions").column("id"))
            .do
            .update
            .set(assignments)
            .where(excluded.column("gate") > 2)
            .returning(Path.Column("id"), Path.Column("value"), Path.Column("gate"))

        #expect(
            noTargetDoNothing.prepare(.duck).plain ==
                #"INSERT INTO "events" ("id", "name") VALUES (1, 'one') ON CONFLICT DO NOTHING"#
        )
        #expect(
            targetDoNothing.prepare(.duck).plain ==
                #"INSERT INTO "events" ("id", "name") VALUES (1, 'one') ON CONFLICT ("id") DO NOTHING"#
        )
        let prepared = doUpdate.prepare(.duck).splitted
        #expect(
            prepared.query ==
                #"INSERT INTO "conflict_actions" ("id", "value", "gate") VALUES ($1, $2, $3) ON CONFLICT ("id") DO UPDATE SET "value" = "EXCLUDED"."value", "gate" = "EXCLUDED"."gate" WHERE "EXCLUDED"."gate" > $4 RETURNING "id", "value", "gate""#
        )
        #expect(prepared.values.map { String(describing: $0) } == ["1", "updated", "3", "2"])
    }

    @Test("Historical ON CONSTRAINT rendering stays unchanged and unclaimed for Duck")
    func onConstraintCompatibilityBoundary() {
        check(
            SwifQL.on.conflict.on.constraint("events_key").do.nothing,
            .duck(#"ON CONFLICT ON CONSTRAINT "events_key" DO NOTHING"#),
            .psql(#"ON CONFLICT ON CONSTRAINT "events_key" DO NOTHING"#),
            .mysql("ON CONFLICT ON CONSTRAINT events_key DO NOTHING")
        )
    }

    @Test("RETURNING columns, star, and expression lists reuse existing composition")
    func returningComposition() {
        let columns = insertValues(events)
            .returning(events.column("id"), events.column("name"))
        let star = insertValues(events).returning.asterisk
        let expression = insertValues(events).returning[
            items: events.column("id") + 1 => "next_id"
        ]
        let starAndExpression = SwifQL.returning[
            items: SwifQL.asterisk, events.column("id") + 1 => "next_id"
        ]

        #expect(
            columns.prepare(.duck).plain ==
                #"INSERT INTO "events" ("id", "name") VALUES (1, 'one') RETURNING "id", "name""#
        )
        #expect(
            star.prepare(.duck).plain ==
                #"INSERT INTO "events" ("id", "name") VALUES (1, 'one') RETURNING *"#
        )
        #expect(
            expression.prepare(.duck).plain ==
                #"INSERT INTO "events" ("id", "name") VALUES (1, 'one') RETURNING "id" + 1 as "next_id""#
        )
        #expect(
            starAndExpression.prepare(.duck).plain ==
                #"RETURNING *, "id" + 1 as "next_id""#
        )

        let preparedExpression = insertValues(events).returning[
            items: events.column("id") + 10 => "next_id"
        ].prepare(.duck).splitted
        #expect(
            preparedExpression.query ==
                #"INSERT INTO "events" ("id", "name") VALUES ($1, $2) RETURNING "id" + $3 as "next_id""#
        )
        #expect(preparedExpression.values.map { String(describing: $0) } == ["1", "one", "10"])
    }

    @Test("UPDATE SET/FROM/WHERE remains direct and bind-ordered")
    func updateComposition() {
        let query = SwifQL
            .update(events)
            .set[items: events.column("name") == "updated"]
            .from(source)
            .where(events.column("id") == 1)
        let prepared = query.prepare(.duck).splitted

        #expect(
            prepared.query ==
                #"UPDATE "events" SET "name" = $1 FROM "event_source" WHERE "events"."id" = $2"#
        )
        #expect(prepared.values.map { String(describing: $0) } == ["updated", "1"])
    }

    @Test("UPDATE RETURNING remains mechanical but unclaimed")
    func updateReturningBoundary() {
        let query = SwifQL
            .update(events)
            .set[items: events.column("name") == "updated"]
            .where(events.column("id") == 1)
            .returning(events.column("id"))

        #expect(
            query.prepare(.duck).plain ==
                #"UPDATE "events" SET "name" = 'updated' WHERE "events"."id" = 1 RETURNING "id""#
        )
    }

    @Test("DELETE USING reuses the generic owner-derived method without DML scopes")
    func deleteUsingComposition() {
        let query = SwifQL
            .delete(from: events)
            .using(source)
            .where(events.column("id") == source.column("id"))
            .returning
            .asterisk

        check(
            query,
            .duck(#"DELETE FROM "events" USING "event_source" WHERE "events"."id" = "event_source"."id" RETURNING *"#),
            .psql(#"DELETE FROM "events" USING "event_source" WHERE "events"."id" = "event_source"."id" RETURNING *"#),
            .mysql("DELETE FROM events USING event_source WHERE events.id = event_source.id RETURNING *")
        )
        #expect(query.structuralOwner(for: .using) == nil)

        let sourceQuery = SwifQL
            .select(source.column("id"))
            .from(source)
            .where(source.column("kind") == "remove")
        let doomed = |(sourceQuery)| => "doomed"
        let subquery = SwifQL
            .delete(from: events)
            .using(doomed)
            .where(events.column("id") == Path.Table("doomed").column("id"))
        let prepared = subquery.prepare(.duck).splitted

        #expect(
            prepared.query ==
                #"DELETE FROM "events" USING (SELECT "event_source"."id" FROM "event_source" WHERE "event_source"."kind" = $1) as "doomed" WHERE "events"."id" = "doomed"."id""#
        )
        #expect(prepared.values.map { String(describing: $0) } == ["remove"])

        let comma = SwifQLableParts(parts: SwifQLPartOperator.comma, SwifQLPartOperator.space)
        let multipleSources = source ~ (comma ~ (|(SwifQL.select(1 => "id"))| => "doomed"))
        let multiple = SwifQL
            .delete(from: events)
            .using(multipleSources)
            .where(events.column("id") == Path.Table("doomed").column("id"))
            .returning.asterisk
        #expect(
            multiple.prepare(.duck).splitted.query ==
                #"DELETE FROM "events" USING "event_source", (SELECT $1 as "id") as "doomed" WHERE "events"."id" = "doomed"."id" RETURNING *"#
        )
        #expect(multiple.prepare(.duck).splitted.values.map { String(describing: $0) } == ["1"])

        func returningQualified(_ base: SwifQLable, _ items: [SwifQLable]) -> SwifQLable {
            var parts: [SwifQLPart] = [SwifQLPartOperator.space]
            for (index, item) in items.enumerated() {
                if index > 0 {
                    parts.append(SwifQLPartOperator.comma)
                    parts.append(SwifQLPartOperator.space)
                }
                parts.append(contentsOf: item.parts)
            }
            return base.returning.structurallyAppending(
                SwifQLableParts(parts: parts)
            )
        }

        let targetQualified = returningQualified(
            SwifQL
            .delete(from: events)
            .using(source)
            .where(events.column("id") == source.column("id")),
            [events.column("id"), events.column("name")]
        )
        let sourceQualified = returningQualified(
            SwifQL
            .delete(from: events)
            .using(source)
            .where(events.column("id") == source.column("id")),
            [source.column("id")]
        )
        #expect(
            targetQualified.prepare(.duck).plain ==
                #"DELETE FROM "events" USING "event_source" WHERE "events"."id" = "event_source"."id" RETURNING "events"."id", "events"."name""#
        )
        #expect(
            sourceQualified.prepare(.duck).plain ==
                #"DELETE FROM "events" USING "event_source" WHERE "events"."id" = "event_source"."id" RETURNING "event_source"."id""#
        )

        let returningExpression = SwifQL
            .delete(from: events)
            .where(events.column("id") == 1)
            .returning[
                items: events.column("id"), events.column("id") + 100 => "id_plus"
            ]
        let returningPrepared = returningExpression.prepare(.duck).splitted
        #expect(
            returningPrepared.query ==
                #"DELETE FROM "events" WHERE "events"."id" = $1 RETURNING "id", "id" + $2 as "id_plus""#
        )
        #expect(returningPrepared.values.map { String(describing: $0) } == ["1", "100"])
    }

    @Test("TRUNCATE preserves exact table qualification and bind-free output")
    func truncateComposition() {
        let query = SwifQL.truncate(Path.Schema("analytics").table("events"))

        check(
            query,
            .duck(#"TRUNCATE "analytics"."events""#),
            .psql(#"TRUNCATE "analytics"."events""#),
            .mysql("TRUNCATE analytics.events")
        )
        #expect(query.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("UPDATE siblings retain direct SQL and explicit unclaimed boundaries")
    func updateSiblingBoundaries() {
        let multipleSet = SwifQL
            .update(events)
            .set[items:
                events.column("name") == "updated",
                events.column("kind") == "changed"
            ]
            .where(events.column("id") == 1)
        #expect(
            multipleSet.prepare(.duck).splitted.query ==
                #"UPDATE "events" SET "name" = $1, "kind" = $2 WHERE "events"."id" = $3"#
        )
        #expect(multipleSet.prepare(.duck).splitted.values.map { String(describing: $0) } == ["updated", "changed", "1"])

        let scalar = |(SwifQL
            .select(source.column("name"))
            .from(source)
            .where(source.column("id") == events.column("id")))|
        let subquery = SwifQL
            .update(events)
            .set[items: events.column("name") == scalar]
            .where(events.column("id") == 1)
        #expect(
            subquery.prepare(.duck).plain ==
                #"UPDATE "events" SET "name" = (SELECT "event_source"."name" FROM "event_source" WHERE "event_source"."id" = "events"."id") WHERE "events"."id" = 1"#
        )

        let multiTarget = SwifQL
            .update(events, source)
            .set[items: events.column("name") == source.column("kind")]
            .where(events.column("id") == source.column("id"))
        #expect(
            multiTarget.prepare(.duck).plain ==
                #"UPDATE "events", "event_source" SET "name" = "kind" WHERE "events"."id" = "event_source"."id""#
        )
    }

    @Test("Representative INSERT UPDATE DELETE helpers survive erasure and copied parts")
    func composedDMLRemainsValueSemantic() {
        func makeInsert() -> SwifQLable {
            insertValues(events)
        }

        func makeUpdate() -> SwifQLable {
            SwifQL
                .update(events)
                .set[items: events.column("name") == "updated"]
                .where(events.column("id") == 1)
        }

        func makeDelete() -> SwifQLable {
            SwifQL
                .delete(from: events)
                .using(source)
                .where(events.column("id") == source.column("id"))
        }

        let fluent = [makeInsert(), makeUpdate(), makeDelete()]
        let erased: [SwifQLable] = fluent.map { $0 }
        let copied = erased.map { SwifQLableParts(parts: $0.parts) }

        for index in fluent.indices {
            #expect(erased[index].prepare(.duck).plain == fluent[index].prepare(.duck).plain)
            #expect(copied[index].prepare(.duck).plain == fluent[index].prepare(.duck).plain)
        }
    }
}
