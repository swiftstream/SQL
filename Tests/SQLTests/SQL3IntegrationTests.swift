import Testing
@testable import SQL

private struct SQL3PlainFixture: Table {
    static var tableName: String { "plain_events" }
    @Column("id") var id: Int
    @Column("payload") var payload: String
    init() {}
}

private struct SQL3SchemaFixture: Table, Schemable {
    static var tableName: String { "schema_events" }
    static var schema: DB.Schema { "tenant" }
    @Column("id") var id: Int
    @Column("payload") var payload: String
    init() {}
}

private struct SQL3CatalogFixture: Table, Catalogable {
    static var tableName: String { "catalog_events" }
    static var schema: DB.Schema { DB.Schema(catalog: "embedded", name: "tenant") }
    static var catalog: DB.Catalog { "model_catalog" }
    @Column("id") var id: Int
    @Column("payload") var payload: String
    init() {}
}

private struct SQL3AnyTableOnlyFixture: AnyTable {
    static var tableName: String { "custom_decodable_name" }
    let value: Int
}

private struct SQL3AliasableOnlyFixture: Aliasable {
    @Alias("id") var id: Int
    init() {}
}

private struct SQL3PlainDecodable: Decodable { let value: Int }
private struct SQL3SchemaDecodable: Decodable, Schemable {
    static var schema: DB.Schema { "decoded_schema" }
    let value: Int
}
private struct SQL3CatalogDecodable: Decodable, Catalogable {
    static var schema: DB.Schema { DB.Schema(catalog: "embedded", name: "decoded_schema") }
    static var catalog: DB.Catalog { "decoded_catalog" }
    let value: Int
}

@Suite("SQL 3 DB identity integration")
struct SQL3IntegrationTests {
    @Test("I301 model, key-path, formatted, manual, and maker parity")
    func i301ModelProducerParity() {
        let expected = [
            #""model_catalog"."tenant"."catalog_events"."id""#,
            "model_catalog.tenant.catalog_events.id",
            #""model_catalog"."tenant"."catalog_events"."id""#
        ]
        let producers: [any SQLable] = [
            SQL3CatalogFixture.$id,
            \SQL3CatalogFixture.$id,
            SQL3CatalogFixture.column("id"),
            FormattedKeyPath(SQL3CatalogFixture.self, "id"),
            FormattedKeyPath(SQL3CatalogFixture.self, ["id"]),
            SQL3CatalogFixture.manualKeyPath("id"),
            SQL3CatalogFixture.manualKeyPath(["id"]),
            SQL3CatalogFixture.mkp("id"),
            SQL3CatalogFixture.mkp(["id"])
        ]
        for producer in producers {
            #expect(producer.parts.count == 1)
            let part = producer.parts.first as? SQLPartKeyPath
            #expect(part?.catalog == "model_catalog")
            #expect(part?.schema == "tenant")
            #expect(part?.table == "catalog_events")
            #expect(part?.paths == ["id"])
            #expect(SQLDialect.all.map { producer.prepare($0).plain } == expected)
        }

        let plain = SQL3PlainFixture.$id
        #expect((plain.parts.first as? SQLPartKeyPath)?.catalog == nil)
        #expect((plain.parts.first as? SQLPartKeyPath)?.schema == nil)
        #expect(plain.prepare(.psql).plain == #""plain_events"."id""#)
        #expect(plain.prepare(.mysql).plain == "plain_events.id")
        let schemaOnly = SQL3SchemaFixture.$id.parts.first as? SQLPartKeyPath
        #expect(schemaOnly?.schema == "tenant")
        let embedded = SQL3SchemaFixture.inSchema(DB.Schema(catalog: "embedded", name: "tenant")).$id
        #expect((embedded.parts.first as? SQLPartKeyPath)?.catalog == "embedded")
        let stringFKP = FormattedKeyPath("manual_table", "id")
        #expect((stringFKP.parts.first as? SQLPartKeyPath)?.catalog == nil)
        #expect((stringFKP.parts.first as? SQLPartKeyPath)?.schema == nil)
        #expect(stringFKP.prepare(.psql).plain == #""manual_table"."id""#)
        #expect(SQL3AnyTableOnlyFixture.table.prepare(.psql).plain == #""custom_decodable_name""#)
    }

    @Test("I302 explicit schema and catalog scopes normalize in both orders")
    func i302ExplicitScopesAndMarkers() {
        let schema = DB.Schema(catalog: "scope_catalog", name: "scope_schema")
        let catalogFirst = SQL3PlainFixture.inCatalog("explicit_catalog").inSchema(schema)
        let schemaFirst = SQL3PlainFixture.inSchema(schema).inCatalog("explicit_catalog")
        #expect(catalogFirst.schema == schemaFirst.schema)
        #expect(catalogFirst.schema == DB.Schema(catalog: "explicit_catalog", name: "scope_schema"))
        #expect(catalogFirst.table.prepare(.psql).plain == #""explicit_catalog"."scope_schema"."plain_events""#)
        #expect(catalogFirst.$id.prepare(.mysql).plain == "explicit_catalog.scope_schema.plain_events.id")

        let embeddedOnly = SQL3CatalogFixture.inSchema(SQL3CatalogFixture.schema)
        #expect(embeddedOnly.schema.catalog == DB.Catalog("embedded"))
        let explicit = SQL3CatalogFixture.inSchema(SQL3CatalogFixture.schema).inCatalog("override")
        #expect(explicit.schema.catalog == DB.Catalog("override"))
        let explicitSchemaWithoutCatalog = SQL3CatalogFixture.inSchema(DB.Schema("explicit_schema"))
        #expect(explicitSchemaWithoutCatalog.schema.catalog == nil)
        #expect(explicitSchemaWithoutCatalog.table.prepare(.psql).plain == #""explicit_schema"."catalog_events""#)
        let marker = Catalog<SQL3SchemaFixture>("marker_catalog")
        #expect(marker.table.prepare(.psql).plain == #""marker_catalog"."tenant"."schema_events""#)
        #expect(marker.inSchema(DB.Schema("other_schema")).table.prepare(.mysql).plain == "marker_catalog.other_schema.schema_events")
        let markerSchemaOverride = Catalog<SQL3CatalogFixture>("marker_catalog")
            .inSchema(DB.Schema("schema_without_catalog"))
        #expect(markerSchemaOverride.table.prepare(.psql).plain == #""marker_catalog"."schema_without_catalog"."catalog_events""#)
        #expect(SQL3SchemaFixture.table(DB.Table("other_table")).prepare(.psql).plain == #""tenant"."other_table""#)
        #expect(SQL3SchemaFixture.path("other_table", "payload", "name").parts.count == 1)
    }

    @Test("I303 broad Decodable table and alias fallback honors qualification")
    func i303BroadDecodable() {
        #expect(SQL3PlainDecodable.table.prepare(.psql).plain == #""SQL3PlainDecodable""#)
        #expect(SQL3SchemaDecodable.table.prepare(.psql).plain == #""decoded_schema"."SQL3SchemaDecodable""#)
        #expect(SQL3CatalogDecodable.table.prepare(.psql).plain == #""decoded_catalog"."decoded_schema"."SQL3CatalogDecodable""#)
        #expect(SQL3AnyTableOnlyFixture.table.prepare(.psql).plain == #""custom_decodable_name""#)
        #expect(SQL3PlainDecodable.as("p").table.prepare(.psql).plain == #""SQL3PlainDecodable" AS "p""#)
        #expect(SQL3SchemaDecodable.as("s").table.prepare(.psql).plain == #""decoded_schema"."SQL3SchemaDecodable" AS "s""#)
        #expect(SQL3CatalogDecodable.as("d").table.prepare(.mysql).plain == "decoded_catalog.decoded_schema.SQL3CatalogDecodable AS d")
    }

    @Test("I304 structural columns, path projections, objects, and row fields")
    func i304StructuralPaths() {
        let plain = DB.Table("events").column("payload", "nested", "leaf")
        let qualified = DB.Schema(catalog: "warehouse", name: "analytics")
            .table("events").column(["payload", "nested", "leaf"])
        let variadic = DB.Column("payload", "nested", "leaf")
        let input = DB.Column(["payload", "nested", "leaf"])
        #expect(variadic.paths == input.paths)
        #expect(DB.Schema("analytics").table("events").column("payload", "leaf").paths == ["payload", "leaf"])
        #expect(plain.parts.count == 1)
        #expect(qualified.parts.count == 1)
        #expect((qualified.parts.first as? SQLPartKeyPath)?.paths == input.paths)
        #expect(plain.name == "payload")
        #expect(plain.lastPath == "leaf")
        let multiPathColumn = DB.Table("events").column(["first", "last"])
        let emptyPathColumn = DB.Table("events").column([String]())
        #expect(multiPathColumn.name == "first")
        #expect(multiPathColumn.lastPath == "last")
        #expect(DB.Column([String]()).paths.isEmpty)
        #expect(DB.Column([String]()).lastPath == "")
        #expect(emptyPathColumn.name == "")
        #expect(emptyPathColumn.lastPath == "")
        #expect(DB.Table("events").column("id").prepare(.psql).plain == #""events"."id""#)

        let objects = [DB.Object("plain"), DB.Object(schema: "scope", name: "scoped"),
            DB.Object(catalog: "warehouse", schema: "scope", name: "qualified"),
            DB.Object(catalog: DB.Catalog("warehouse"), schema: DB.Schema("scope"), name: "typed")]
        #expect(objects.map { $0.prepare(.psql).plain } == [#""plain""#, #""scope"."scoped""#,
            #""warehouse"."scope"."qualified""#, #""warehouse"."scope"."typed""#])
        #expect(Row(DB.Column("id"), DB.Table("events").column("payload")).prepare(.psql).plain == #"ROW("id", "events"."payload")"#)
        let projection = SQL { Select { DB.Column("id"); DB.Table("events").column("payload") } }
        #expect(projection.prepare(.psql).plain == #"SELECT "id", "events"."payload""#)
    }

    @Test("I305 aliases separate full source identity from alias-only references")
    func i305AliasOwnership() {
        let legacyNil = GenericTableAlias<SQL3CatalogFixture>("legacy_nil", schema: nil)
        let legacyLiteral = GenericTableAlias<SQL3CatalogFixture>("legacy_literal", schema: "literal_schema")
        let literalVariable = "variable_schema"
        let legacyVariable = GenericTableAlias<SQL3CatalogFixture>("legacy_variable", schema: literalVariable)
        let explicitSource = GenericTableAlias<SQL3CatalogFixture>(
            "explicit_source", sourceSchema: DB.Schema(catalog: "source_catalog", name: "source_schema")
        )
        #expect((legacyNil.table.parts.first as? SQLPartTableWithAlias)?.catalog == "model_catalog")
        #expect((legacyNil.table.parts.first as? SQLPartTableWithAlias)?.schema == "tenant")
        #expect((legacyLiteral.table.parts.first as? SQLPartTableWithAlias)?.catalog == nil)
        #expect((legacyLiteral.table.parts.first as? SQLPartTableWithAlias)?.schema == "literal_schema")
        #expect((legacyVariable.table.parts.first as? SQLPartTableWithAlias)?.catalog == nil)
        #expect((legacyVariable.table.parts.first as? SQLPartTableWithAlias)?.schema == "variable_schema")
        #expect((explicitSource.table.parts.first as? SQLPartTableWithAlias)?.catalog == "source_catalog")
        #expect((explicitSource.table.parts.first as? SQLPartTableWithAlias)?.table == "catalog_events")
        #expect(explicitSource.parts.count == 1)
        #expect((explicitSource.parts.first as? SQLPartTable)?.table == "explicit_source")
        #expect(explicitSource.column("payload").prepare(.psql).plain == #""explicit_source"."payload""#)
        #expect(explicitSource.$payload.prepare(.mysql).plain == "explicit_source.payload")
        let aliasReference = explicitSource.column("payload", "field")
        let aliasReferencePart = aliasReference.parts.first as? SQLPartKeyPath
        #expect(aliasReference.parts.count == 1)
        #expect(aliasReferencePart?.catalog == nil)
        #expect(aliasReferencePart?.schema == nil)
        #expect(aliasReferencePart?.table == "explicit_source")
        #expect(aliasReference.prepare(.psql).plain == #""explicit_source"."payload"->'field'"#)
        #expect((explicitSource.parts.first as? SQLPartTable)?.table == "explicit_source")
        let aliasStar = explicitSource.*
        #expect(aliasStar.prepare(.psql).plain == #""explicit_source".* "#)
        let schemaAlias = SQL3CatalogFixture.inSchema(DB.Schema(catalog: "marker_catalog", name: "marker_schema")).as("marker_alias")
        #expect((schemaAlias.table.parts.first as? SQLPartTableWithAlias)?.catalog == "marker_catalog")
        let idKeyPath: KeyPath<SQL3CatalogFixture, Column<Int>> = \SQL3CatalogFixture.$id
        let aliasedKey = AliasedKeyPath<KeyPath<SQL3CatalogFixture, Column<Int>>, SQL3CatalogFixture, Column<Int>>("a", idKeyPath)
        #expect(aliasedKey.schema == "tenant")
        #expect(aliasedKey.table == "a")
        #expect(aliasedKey.paths == ["id"])
        #expect(aliasedKey.parts.count == 1)
        #expect(aliasedKey.parts.first is SQLPartKeyPath)
        let aliasableFallback = GenericTableAlias<SQL3AliasableOnlyFixture>("fallback", schema: nil)
        #expect((aliasableFallback.table.parts.first as? SQLPartTableWithAlias)?.schema == nil)
        #expect((aliasableFallback.table.parts.first as? SQLPartTableWithAlias)?.table == "SQL3AliasableOnlyFixture")
    }

    @Test("I306 existing DDL constructors preserve qualification boundaries")
    func i306ExistingDDL() {
        let modelDDL = SQL.create.table[any: SQL3CatalogFixture.table]
        let explicitDDL = SQL.create.table[any: DB.Catalog("ddl_catalog").schema("ddl_schema").table("ddl_table")]
        let stringDDL = SQL.create.table[any: DB.Table("plain_ddl")]
        #expect(modelDDL.prepare(.psql).plain == #"CREATE TABLE "model_catalog"."tenant"."catalog_events""#)
        #expect(explicitDDL.prepare(.duck).plain == #"CREATE TABLE "ddl_catalog"."ddl_schema"."ddl_table""#)
        #expect(stringDDL.prepare(.mysql).plain == "CREATE TABLE plain_ddl")
        #expect(SQL.drop.table[any: SQL3CatalogFixture.table].prepare(.psql).plain == #"DROP TABLE "model_catalog"."tenant"."catalog_events""#)
        let references = Constraint.references(SQL3CatalogFixture.self)
        #expect(references.query.prepare(.psql).plain == #"REFERENCES "model_catalog"."tenant"."catalog_events""#)
        let stringReferences = Constraint.references(nil, "plain_reference")
        #expect(stringReferences.query.prepare(.psql).plain == #"REFERENCES "plain_reference""#)

        #expect(CreateTableBuilder<SQL3CatalogFixture>().prepare(.psql).plain == #"CREATE TABLE "model_catalog"."tenant"."catalog_events" ()"#)
        #expect(DropTableBuilder<SQL3CatalogFixture>().prepare(.psql).plain == #"DROP TABLE "catalog_events""#)
        #expect(UpdateTableBuilder<SQL3CatalogFixture>().addColumn("new_column", .integer).prepare(.psql).plain == #"ALTER TABLE "model_catalog"."tenant"."catalog_events" ADD COLUMN "new_column" integer;"#)
        #expect(UpdateTableBuilder<SQL3CatalogFixture>().renameTable(to: "renamed_events").prepare(.psql).plain == #"ALTER TABLE "model_catalog"."tenant"."catalog_events" RENAME TO "renamed_events";"#)
        #expect(UpdateTableBuilder<SQL3CatalogFixture>().createIndex(name: "catalog_events_id_idx", items: .column("id")).prepare(.psql).plain == #"CREATE INDEX "catalog_events_id_idx" ON "model_catalog"."tenant"."catalog_events"("id");"#)

        #expect(CreateTableBuilder<SQL3PlainFixture>(schema: SQL3CatalogDecodable.self).prepare(.psql).plain == #"CREATE TABLE "decoded_catalog"."decoded_schema"."plain_events" ()"#)
        #expect(UpdateTableBuilder<SQL3PlainFixture>(schema: SQL3CatalogDecodable.self).addColumn("new_column", .integer).prepare(.psql).plain == #"ALTER TABLE "decoded_catalog"."decoded_schema"."plain_events" ADD COLUMN "new_column" integer;"#)
        #expect(CreateTableBuilder<SQL3PlainFixture>(schema: "string_schema").prepare(.psql).plain == #"CREATE TABLE "string_schema"."plain_events" ()"#)
        #expect(UpdateTableBuilder<SQL3PlainFixture>(schema: "string_schema").addColumn("new_column", .integer).prepare(.psql).plain == #"ALTER TABLE "string_schema"."plain_events" ADD COLUMN "new_column" integer;"#)

        #expect(CreateSchemaBuilder<SQL3CatalogDecodable>().prepare(.psql).plain == #"CREATE SCHEMA "decoded_catalog"."decoded_schema""#)
        #expect(DropSchemaBuilder<SQL3CatalogDecodable>().prepare(.psql).plain == #"DROP SCHEMA "decoded_catalog"."decoded_schema""#)
        #expect(UpdateSchemaRenameBuilder<SQL3CatalogDecodable>().newName("renamed_schema").prepare(.psql).plain == #"ALTER SCHEMA "decoded_catalog"."decoded_schema" RENAME TO "renamed_schema""#)
        #expect(UpdateSchemaChangeOwner<SQL3CatalogDecodable>().newOwner("new_owner").prepare(.psql).plain == #"ALTER SCHEMA "decoded_catalog"."decoded_schema" OWNER TO "new_owner""#)
    }

    @Test("I307 source constructors and copied or erased semantic parts retain defaults")
    func i307AtomicSourcesAndCopy() {
        let legacyTable = SQLPartTable("events")
        let legacyAlias = SQLPartTableWithAlias(schema: nil, table: "events", alias: "e")
        #expect(legacyTable.catalog == nil)
        #expect(legacyAlias.catalog == nil)
        let legacyKeyPathVariadic = SQLPartKeyPath(schema: "analytics", table: "events", paths: "payload", "field")
        let legacyKeyPathArray = SQLPartKeyPath(schema: "analytics", table: "events", paths: ["payload", "field"])
        let catalogKeyPathVariadic = SQLPartKeyPath(catalog: "warehouse", schema: "analytics", table: "events", paths: "payload", "field")
        let catalogKeyPathArray = SQLPartKeyPath(catalog: "warehouse", schema: "analytics", table: "events", paths: ["payload", "field"])
        #expect(legacyKeyPathVariadic.catalog == nil)
        #expect(legacyKeyPathArray.catalog == nil)
        #expect(catalogKeyPathVariadic.catalog == "warehouse")
        #expect(catalogKeyPathArray.paths == ["payload", "field"])
        let source = DB.Catalog("warehouse").schema("analytics").table("events")
        let copied = SQLableParts(parts: source.parts)
        let erased: any SQLable = source
        #expect(copied.parts.count == 1)
        #expect((copied.parts.first as? SQLPartTable)?.catalog == "warehouse")
        #expect(erased.parts.count == 1)
        #expect(erased.prepare(.psql).plain == #""warehouse"."analytics"."events""#)
        #expect(SQL3AnyTableOnlyFixture.as("x").table.prepare(.psql).plain == #""custom_decodable_name" AS "x""#)
    }

    @Test("I308 inferred SQLable predicates render both structural operands")
    func i308PredicateInference() {
        let lhs = DB.Table("left_events").column("payload", "field")
        let rhs = DB.Table("right_events").column("payload", "field")
        let predicate = lhs == rhs
        #expect(predicate.prepare(.psql).plain == #""left_events"."payload"->'field' = "right_events"."payload"->'field'"#)
        #expect(predicate.prepare(.mysql).plain == "left_events.field = right_events.field")
        #expect(predicate.prepare(.duck).plain == #"("left_events"."payload"->'field') = ("right_events"."payload"->'field')"#)
        #expect(predicate.prepare(.psql).splitted.values.isEmpty)
        let plainNested = DB.Column("payload", "field") == DB.Column("other_payload", "leaf")
        #expect(plainNested.prepare(.psql).plain == #""payload"->'field' = "other_payload"->'leaf'"#)
        #expect(plainNested.prepare(.mysql).plain == "field = leaf")
        #expect(plainNested.prepare(.duck).plain == #"("payload"->'field') = ("other_payload"->'leaf')"#)
        #expect(plainNested.prepare(.psql).splitted.values.isEmpty)
        let inequality = DB.Column("left_id") != DB.Column("right_id")
        let inequalityPrepared = inequality.prepare(.psql)
        #expect(inequalityPrepared.plain == #""left_id" != "right_id""#)
        #expect(inequalityPrepared.splitted.values.isEmpty)
        let directFluent = SQL.select(DB.Table("events").column("id"))
            .from(DB.Table("events"))
            .where(DB.Table("events").column("left_id") == DB.Table("other_events").column("right_id"))
        let directFluentPrepared = directFluent.prepare(.psql)
        #expect(directFluentPrepared.plain == #"SELECT "events"."id" FROM "events" WHERE "events"."left_id" = "other_events"."right_id""#)
        #expect(directFluentPrepared.splitted.values.isEmpty)
        let declarative = SQL {
            Select { DB.Column("id") }
            From { DB.Table("events") }
            Where { DB.Table("events").column("payload", "field") == DB.Table("other").column("payload", "field") }
        }
        let declarativePrepared = declarative.prepare(.psql)
        #expect(declarativePrepared.plain == #"SELECT "id" FROM "events" WHERE "events"."payload"->'field' = "other"."payload"->'field'"#)
        #expect(declarativePrepared.splitted.values.isEmpty)
        #expect(DB.Catalog("a") == DB.Catalog("a"))
        #expect(DB.Schema("a") == DB.Schema("a"))
    }

    @Test("I309 intentional terminal projections remain explicit and usable")
    func i309ProjectionBoundaries() {
        let qualified = DB.Schema("analytics").table("events").column("payload", "terminal")
        #expect(((DB.Table("events") as SQLable) => DB.Table("table_alias")).prepare(.psql).plain == #""events" as "table_alias""#)
        #expect(((DB.Schema("analytics").table("events") as SQLable) => DB.Schema("other").table("schema_alias")).prepare(.psql).plain == #""analytics"."events" as "schema_alias""#)
        #expect(SQL.select(qualified).prepare(.psql).plain == #"SELECT "analytics"."events"."payload"->'terminal'"#)
        #expect(SQL.select(qualified).items(qualified).prepare(.psql).plain.contains(#""payload""#))
        let fields = SQLableParts(parts: SQLPartOperator("INSERT INTO records")).fields(qualified)
        #expect(fields.prepare(.psql).plain == #"INSERT INTO records ("terminal")"#)
        #expect(qualified.lastPath == "terminal")
        #expect(SQL.select(qualified).prepare(.psql).splitted.values.isEmpty)
    }

    @Test("I310 SQLable composition retains binding order and qualification provenance")
    func i310CompositionBindingAndProvenance() {
        let table = DB.Catalog("warehouse").schema("analytics").table("events")
        let column = table.column("payload")
        let oneChain = SQL.select(column).from(table).where(column == "match")
        var incremental: any SQLable = SQL.select(column)
        incremental = incremental.from(table)
        incremental = incremental.where(column == "match")
        let copied = SQLableParts(parts: oneChain.parts)
        for query in [oneChain, incremental, copied] {
            let prepared = query.prepare(.psql)
            #expect(prepared.plain == #"SELECT "warehouse"."analytics"."events"."payload" FROM "warehouse"."analytics"."events" WHERE "warehouse"."analytics"."events"."payload" = 'match'"#)
            #expect(prepared.splitted.query == #"SELECT "warehouse"."analytics"."events"."payload" FROM "warehouse"."analytics"."events" WHERE "warehouse"."analytics"."events"."payload" = $1"#)
            #expect(prepared.splitted.values.map { String(describing: $0) } == ["match"])
            #expect(query.prepare(.mysql).plain == "SELECT warehouse.analytics.events.payload FROM warehouse.analytics.events WHERE warehouse.analytics.events.payload = 'match'")
            #expect(query.prepare(.mysql).splitted.query == "SELECT warehouse.analytics.events.payload FROM warehouse.analytics.events WHERE warehouse.analytics.events.payload = ?")
            #expect(query.prepare(.duck).plain == #"SELECT "warehouse"."analytics"."events"."payload" FROM "warehouse"."analytics"."events" WHERE "warehouse"."analytics"."events"."payload" = 'match'"#)
        }
        #expect(oneChain.parts.count == copied.parts.count)
        let observed = oneChain.prepareObservingUnsafeValues(.psql)
        #expect(observed.prepared.splitted.query == oneChain.prepare(.psql).splitted.query)
        switch observed.unsafeValueTrace {
        case .complete(let occurrences):
            #expect(occurrences.map(\.disposition) == [.bound(index: 0)])
        case .unavailable:
            Issue.record("Expected the same-render unsafe-value trace to be complete")
        }
    }

    @Test("I311 PostgreSQL JSON and Duck scoped key paths preserve their boundaries")
    func i311JSONAndDuckScopes() {
        let json = DB.Table("events").column("payload", "field")
        #expect(SQL.select(json).prepare(.psql).plain == #"SELECT "events"."payload"->'field'"#)
        #expect(SQL.select(json).prepare(.duck).plain == #"SELECT ("events"."payload"->'field')"#)
        #expect(SQL.select(json).prepare(.mysql).plain == "SELECT events.field")
        let textPath = SQLableParts(parts: SQLPartKeyPath(
            catalog: "warehouse", schema: "analytics", table: "events",
            paths: ["payload", "field"], asText: true
        ))
        #expect(textPath.prepare(.psql).plain == #""warehouse"."analytics"."events"."payload"->>'field'"#)
        #expect(textPath.prepare(.mysql).plain == "warehouse.analytics.events.field")
        let qualified = DB.Catalog("warehouse").schema("analytics").table("events")
        let pivot = SQL.pivot(DB.Table("events"))
            .on(qualified.column("year"), in: 2000)
            .using(qualified.column("population"))
            .groupBy(qualified.column("country"))
            .orderBy(.desc(qualified.column("country")))
        #expect(pivot.prepare(.duck).plain == #"PIVOT "events" ON "year" IN (2000) USING "population" GROUP BY "country" ORDER BY "country" DESC"#)
        let unpivot = SQL.unpivot(DB.Table("events"))
            .on(qualified.column("Jan"), qualified.column("Feb"))
            .into(name: "month", value: "sales")
        let copied = SQLableParts(parts: unpivot.parts)
        #expect(unpivot.prepare(.duck).plain == #"UNPIVOT "events" ON "warehouse"."analytics"."events"."Jan", "warehouse"."analytics"."events"."Feb" INTO NAME "month" VALUE "sales""#)
        #expect(unpivot.prepare(.duck).plain == copied.prepare(.duck).plain)
    }
}
