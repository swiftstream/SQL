import Testing
@testable import SQL

private struct Task22IndexTable: Table, Schemable {
    static var tableName: String { "task22_events" }
    static var schemaName: String { "task22_schema" }

    init() {}
}

@Suite("Duck direct type and index DDL")
struct DuckTypeIndexTests: SwifQLTests {
    private func helperEnumSource() -> SwifQLable {
        var query: SwifQLable = SwifQL.create.type[any: Path.Identifier("status")]
        query = query.as
        return query.enum("open", "closed")
    }

    private func helperIndexSource() -> SwifQLable {
        var query: SwifQLable = SwifQL.create.index[any: Path.Identifier("events_id_idx")]
        query = query.on[any: Path.Table("events")]
        return query.indexItems(.column("id"))
    }

    @Test("ENUM labels are safe parser literals and never ordinary binds")
    func enumLiteralBody() {
        let query = SwifQL.create.type[any: Path.Identifier("status")]
            .as
            .enum("open", "it's", "名前")
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == #"CREATE TYPE "status" as ENUM ('open', 'it''s', '名前')"#)
        #expect(prepared.splitted.query == prepared.plain)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("ENUM SELECT preserves child query composition and bind boundaries")
    func enumSelectBody() {
        let staticQuery = SwifQL.create.type[any: Path.Identifier("status")]
            .as
            .enum(select: SwifQL.select(Path.Column("label")).from(Path.Table("labels")))
        #expect(
            staticQuery.prepare(.duck).plain ==
                #"CREATE TYPE "status" as ENUM (SELECT "label" FROM "labels")"#
        )

        let dynamicQuery = SwifQL.create.type[any: Path.Identifier("status")]
            .as
            .enum(select: SwifQL.select("label").from(Path.Table("labels")))
        let prepared = dynamicQuery.prepare(.duck)
        #expect(prepared.plain == #"CREATE TYPE "status" as ENUM (SELECT 'label' FROM "labels")"#)
        #expect(prepared.splitted.query == #"CREATE TYPE "status" as ENUM (SELECT $1 FROM "labels")"#)
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? String == "label")
    }

    @Test("STRUCT, UNION, scalar aliases, and DROP TYPE reuse existing Type vocabulary")
    func namedTypes() {
        let structure = SwifQL.create.type[any: Path.Identifier("payload")]
            .as(Type.`struct`(("id", .integer), ("label", .varchar)))
        let union = SwifQL.create.type[any: Path.Identifier("choice")]
            .as(Type.union(("number", .integer), ("string", .varchar)))
        let alias = SwifQL.create.type[any: Path.Identifier("cents")].as(.integer)
        let drop = SwifQL.drop.type.if.exists[any: Path.Identifier("status")]

        #expect(
            structure.prepare(.duck).plain ==
                #"CREATE TYPE "payload" as STRUCT("id" integer, "label" varchar)"#
        )
        #expect(
            union.prepare(.duck).plain ==
                #"CREATE TYPE "choice" as UNION("number" integer, "string" varchar)"#
        )
        #expect(alias.prepare(.duck).plain == #"CREATE TYPE "cents" as integer"#)
        #expect(drop.prepare(.duck).plain == #"DROP TYPE IF EXISTS "status""#)
    }

    @Test("TYPE modifier and DROP TYPE siblings remain direct mechanical atoms")
    func typeModifiersAndDrops() {
        let replace = SwifQL.create.or.replace.type[any: Path.Identifier("status")]
            .as
            .enum("open", "closed")
        let ifNotExists = SwifQL.create.type.if.not.exists[any: Path.Identifier("status")]
            .as
            .enum("open", "closed")
        let restrict = SwifQL.drop.type[any: Path.Identifier("status")].restrict
        let cascade = SwifQL.drop.type[any: Path.Identifier("status")].cascade

        #expect(
            replace.prepare(.duck).plain ==
                #"CREATE OR REPLACE TYPE "status" as ENUM ('open', 'closed')"#
        )
        #expect(
            ifNotExists.prepare(.duck).plain ==
                #"CREATE TYPE IF NOT EXISTS "status" as ENUM ('open', 'closed')"#
        )
        #expect(restrict.prepare(.duck).plain == #"DROP TYPE "status" RESTRICT"#)
        #expect(cascade.prepare(.duck).plain == #"DROP TYPE "status" CASCADE"#)
        #expect(replace.prepare(.duck).splitted.values.isEmpty)
        #expect(ifNotExists.prepare(.duck).splitted.values.isEmpty)
        #expect(restrict.prepare(.duck).splitted.values.isEmpty)
        #expect(cascade.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Direct indexItems owns only the parenthesized IndexItem list")
    func directIndexItems() {
        let table = Path.Table("events")
        let basic = SwifQL.create.index[any: Path.Identifier("events_id_idx")]
            .on[any: table]
            .indexItems(.column("id"))
        let unique = SwifQL.create.unique.index.if.not.exists[
            any: Path.Identifier("events_unique_idx")
        ]
        .on[any: table]
        .indexItems(
            .column("tenant"),
            .column("id", order: .descNullsLast)
        )
        let expression = SwifQL.create.index[any: Path.Identifier("events_expr_idx")]
            .on[any: table]
            .indexItems(.expression(Path.Column("x") + Path.Column("y")))
        let art = SwifQL.create.index[any: Path.Identifier("events_art_idx")]
            .on[any: table]
            .using(IndexType.art)
            .indexItems(.column("id"))
        let drop = SwifQL.drop.index.if.exists[any: Path.Identifier("events_id_idx")]
        let replace = SwifQL.create.or.replace.index[any: Path.Identifier("idx")]
            .on[any: table]
            .indexItems(.column("id"))
        let partial = basic.where(Path.Column("id") > 0)
        let dropRestrict = SwifQL.drop.index[any: Path.Identifier("idx")].restrict
        let dropCascade = SwifQL.drop.index[any: Path.Identifier("idx")].cascade

        #expect(basic.prepare(.duck).plain == #"CREATE INDEX "events_id_idx" ON "events" ("id")"#)
        #expect(
            unique.prepare(.duck).plain ==
                #"CREATE UNIQUE INDEX IF NOT EXISTS "events_unique_idx" ON "events" ("tenant", "id" DESC NULLS LAST)"#
        )
        #expect(
            expression.prepare(.duck).plain ==
                #"CREATE INDEX "events_expr_idx" ON "events" (("x" + "y"))"#
        )
        #expect(art.prepare(.duck).plain == #"CREATE INDEX "events_art_idx" ON "events" USING ART ("id")"#)
        #expect(drop.prepare(.duck).plain == #"DROP INDEX IF EXISTS "events_id_idx""#)
        #expect(replace.prepare(.duck).plain == #"CREATE OR REPLACE INDEX "idx" ON "events" ("id")"#)
        #expect(
            partial.prepare(.duck).plain ==
                #"CREATE INDEX "events_id_idx" ON "events" ("id") WHERE "id" > 0"#
        )
        #expect(dropRestrict.prepare(.duck).plain == #"DROP INDEX "idx" RESTRICT"#)
        #expect(dropCascade.prepare(.duck).plain == #"DROP INDEX "idx" CASCADE"#)
        #expect(basic.prepare(.duck).splitted.values.isEmpty)
        #expect(replace.prepare(.duck).splitted.values.isEmpty)
        #expect(
            partial.prepare(.duck).splitted.query ==
                #"CREATE INDEX "events_id_idx" ON "events" ("id") WHERE "id" > $1"#
        )
        #expect(partial.prepare(.duck).splitted.values.count == 1)
        #expect(partial.prepare(.duck).splitted.values[0] as? Int == 0)
    }

    @Test("IndexType spellings and historical IndexItem orders remain generic")
    func indexTypeAndHistoricalItems() {
        #expect(IndexType.btree.prepare(.duck).plain == "BTREE")
        #expect(IndexType.hash.prepare(.duck).plain == "HASH")
        #expect(IndexType.gist.prepare(.duck).plain == "GIST")
        #expect(IndexType.gin.prepare(.duck).plain == "GIN")
        #expect(IndexType.spgist.prepare(.duck).plain == "SPGIST")
        #expect(IndexType.brin.prepare(.duck).plain == "BRIN")
        #expect(IndexType.art.prepare(.duck).plain == "ART")

        #expect(IndexItem.column("id", order: .asc).prepare(.any).plain == "id")
        #expect(IndexItem.column("id", order: .ascNullsFirst).prepare(.any).plain == "id NULLS FIRST")
        #expect(IndexItem.column("id", order: .desc).prepare(.any).plain == "id DESC")
        #expect(IndexItem.column("id", order: .descNullsLast).prepare(.any).plain == "id DESC NULLS LAST")

        let ascending = SwifQL.create.index[any: Path.Identifier("ordered_asc_idx")]
            .on[any: Path.Table("events")]
            .indexItems(.column("id", order: .asc))
        let ascNullsFirst = SwifQL.create.index[any: Path.Identifier("ordered_asc_nulls_first_idx")]
            .on[any: Path.Table("events")]
            .indexItems(.column("id", order: .ascNullsFirst))
        let descending = SwifQL.create.index[any: Path.Identifier("ordered_desc_idx")]
            .on[any: Path.Table("events")]
            .indexItems(.column("id", order: .desc))
        let descNullsLast = SwifQL.create.index[any: Path.Identifier("ordered_desc_nulls_last_idx")]
            .on[any: Path.Table("events")]
            .indexItems(.column("id", order: .descNullsLast))

        #expect(
            ascending.prepare(.duck).plain ==
                #"CREATE INDEX "ordered_asc_idx" ON "events" ("id")"#
        )
        #expect(
            ascNullsFirst.prepare(.duck).plain ==
                #"CREATE INDEX "ordered_asc_nulls_first_idx" ON "events" ("id" NULLS FIRST)"#
        )
        #expect(
            descending.prepare(.duck).plain ==
                #"CREATE INDEX "ordered_desc_idx" ON "events" ("id" DESC)"#
        )
        #expect(
            descNullsLast.prepare(.duck).plain ==
                #"CREATE INDEX "ordered_desc_nulls_last_idx" ON "events" ("id" DESC NULLS LAST)"#
        )
        #expect(ascending.prepare(.duck).splitted.values.isEmpty)
        #expect(ascNullsFirst.prepare(.duck).splitted.values.isEmpty)
        #expect(descending.prepare(.duck).splitted.values.isEmpty)
        #expect(descNullsLast.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("TYPE and INDEX sources preserve direct, erased, copied, and helper composition")
    func typeAndIndexComposition() {
        let directType = SwifQL.create.type[any: Path.Identifier("status")]
            .as
            .enum("open", "closed")
        var erasedType: SwifQLable = SwifQL.create.type[any: Path.Identifier("status")]
        erasedType = erasedType.as
        erasedType = erasedType.enum("open", "closed")
        let copiedType = SwifQLableParts(parts: directType.parts)
        let helperType = helperEnumSource()

        let directIndex = SwifQL.create.index[any: Path.Identifier("events_id_idx")]
            .on[any: Path.Table("events")]
            .indexItems(.column("id"))
        var erasedIndex: SwifQLable = SwifQL.create.index[any: Path.Identifier("events_id_idx")]
        erasedIndex = erasedIndex.on[any: Path.Table("events")]
        erasedIndex = erasedIndex.indexItems(.column("id"))
        let copiedIndex = SwifQLableParts(parts: directIndex.parts)
        let helperIndex = helperIndexSource()

        let typePlain = directType.prepare(.duck).plain
        let indexPlain = directIndex.prepare(.duck).plain
        for candidate in [erasedType, copiedType, helperType] {
            #expect(candidate.prepare(.duck).plain == typePlain)
            #expect(candidate.prepare(.duck).splitted.values.isEmpty)
        }
        for candidate in [erasedIndex, copiedIndex, helperIndex] {
            #expect(candidate.prepare(.duck).plain == indexPlain)
            #expect(candidate.prepare(.duck).splitted.values.isEmpty)
        }
    }

    @Test("Historical UpdateTableBuilder index SQL remains byte-for-byte unchanged")
    func historicalIndexBuilders() {
        let create = UpdateTableBuilder<Task22IndexTable>().createIndex(
            unique: true,
            name: "aaa",
            items: .column("column3", order: .desc),
                .expression(SwifQLBool(true) == SwifQLBool(true)),
            type: .hash,
            where: SwifQLBool(true) == SwifQLBool(true)
        )
        let drop = UpdateTableBuilder<Task22IndexTable>().dropIndex(name: "aaa")

        #expect(
            create.prepare(.psql).plain ==
                #"CREATE UNIQUE INDEX "aaa" ON "task22_schema"."task22_events" USING HASH ("column3" DESC, (TRUE = TRUE)) WHERE TRUE = TRUE;"#
        )
        #expect(
            create.prepare(.duck).plain ==
                #"CREATE UNIQUE INDEX "aaa" ON "task22_schema"."task22_events" USING HASH ("column3" DESC, (TRUE = TRUE)) WHERE TRUE = TRUE;"#
        )
        #expect(drop.prepare(.psql).plain == #"DROP INDEX "aaa";"#)
        #expect(drop.prepare(.duck).plain == #"DROP INDEX "aaa";"#)
    }
}
