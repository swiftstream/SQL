import Testing
@testable import SQL

private struct FoundationTable: Table, Schemable {
    static var tableName: String { "foundation_table" }
    static var schema: DB.Schema { "foundation_schema" }

    @Column("id")
    var id: Int

    init() {}
}

private struct FoundationCatalogTable: Table, Catalogable {
    static var tableName: String { "catalog_table" }
    static var schema: DB.Schema { DB.Schema(catalog: "embedded", name: "model_schema") }
    static var catalog: DB.Catalog { "model_catalog" }

    @Column("id")
    var id: Int

    init() {}
}

private struct FoundationPlainTable: Table {
    static var tableName: String { "plain_table" }

    @Column("id")
    var id: Int

    init() {}
}

private struct FoundationPlainDecodable: Decodable {
    let value: Int
}

@Suite("SQL 3 foundation values and type-state")
struct SQL3FoundationTests {
    @Test("F01-F04 catalog values are immutable string-literal values")
    func catalogValues() {
        let catalog: DB.Catalog = "warehouse"
        #expect(catalog.name == "warehouse")
        #expect(DB.Catalog("warehouse") == catalog)
    }

    @Test("F05-F08 schema values retain names and optional catalog")
    func schemaValues() {
        let schema: DB.Schema = "analytics"
        let qualified = DB.Schema(catalog: "warehouse", name: "analytics")

        #expect(schema.name == "analytics")
        #expect(schema.catalog == nil)
        #expect(qualified.name == "analytics")
        #expect(qualified.catalog == DB.Catalog("warehouse"))
    }

    @Test("F09 replacing a schema catalog preserves its name")
    func schemaCatalogReplacement() {
        let schema = DB.Schema(catalog: "old", name: "analytics")
            .inCatalog("new")

        #expect(schema == DB.Schema(catalog: "new", name: "analytics"))
    }

    @Test("F10-F13 explicit catalog and schema type-state preserve generic access")
    func typedQualification() {
        let schema = FoundationTable.inSchema(DB.Schema("tenant"))
        let schemaValue = Schema<FoundationTable>(DB.Schema("tenant"))
        let fromCatalog = FoundationTable.inCatalog("warehouse")
            .inSchema(DB.Schema(catalog: "embedded", name: "tenant"))

        #expect(schema.schema == schemaValue.schema)
        #expect(fromCatalog.schema == DB.Schema(catalog: "warehouse", name: "tenant"))
        #expect(schema.table.prepare(.psql).plain == #""tenant"."foundation_table""#)
        #expect(schema.$id.prepare(.psql).plain == #""tenant"."foundation_table"."id""#)
        let catalog = FoundationTable.inCatalog("warehouse")
        #expect(catalog.normalizedSchema == DB.Schema(catalog: "warehouse", name: "foundation_schema"))
        _ = catalog.table
        _ = catalog.$id
    }

    @Test("F11 explicit qualification order normalizes to the same state")
    func explicitOrderNormalization() {
        let catalogFirst = FoundationTable.inCatalog("warehouse")
            .inSchema(DB.Schema(catalog: "embedded", name: "tenant"))
        let schemaFirst = FoundationTable.inSchema(
            DB.Schema(catalog: "embedded", name: "tenant")
        ).inCatalog("warehouse")

        #expect(catalogFirst.schema == schemaFirst.schema)
        #expect(catalogFirst.schema == DB.Schema(catalog: "warehouse", name: "tenant"))
    }

    @Test("F14 Catalogable default catalog takes precedence over embedded model schema catalog")
    func catalogableDefaultPrecedence() {
        let resolvedSchema = FoundationCatalogTable.inSchema(FoundationCatalogTable.self)

        #expect(
            resolvedSchema.schema ==
                DB.Schema(catalog: FoundationCatalogTable.catalog, name: "model_schema")
        )
    }

    @Test("F15 schema-only qualification retains an embedded catalog")
    func embeddedCatalogPreservation() {
        let schema = FoundationCatalogTable.inSchema(FoundationCatalogTable.schema)

        #expect(schema.schema == FoundationCatalogTable.schema)
    }

    @Test("F16 explicit catalog replaces an embedded schema catalog")
    func explicitCatalogOverride() {
        let schema = FoundationCatalogTable.inSchema(FoundationCatalogTable.schema)
            .inCatalog("explicit")

        #expect(schema.schema == DB.Schema(catalog: "explicit", name: "model_schema"))
    }

    @Test("F17 DB structural values progress through table and column metadata")
    func structuralProgression() {
        let tableColumn = DB.Table("events").column("id")
        let schemaColumn = DB.Schema("analytics").table("events").column("id")
        let catalogColumn = DB.Catalog("warehouse")
            .schema(DB.Schema("analytics"))
            .table("events")
            .column("id")

        #expect(tableColumn.table.name == "events")
        #expect(tableColumn.name == "id")
        #expect(schemaColumn.schema.name == "analytics")
        #expect(schemaColumn.table == "events")
        #expect(schemaColumn.name == "id")
        #expect(catalogColumn.schema == DB.Schema(catalog: "warehouse", name: "analytics"))
        #expect(catalogColumn.table == "events")
        #expect(catalogColumn.name == "id")
    }

    // F18 is protected by declaration review: DB.Catalog, DB.Schema, and DB.Table
    // explicitly conform to Equatable and Sendable without Hashable conformance.

    @Test("F19 existing schema based SQL rendering remains byte-for-byte stable")
    func schemaRenderingCompatibility() {
        let createTable = CreateTableBuilder<FoundationTable>()
            .column(\.$id, .integer)
        let reference = Constraint.references(FoundationTable.self)

        #expect(
            createTable.prepare(.psql).plain ==
                #"CREATE TABLE "foundation_schema"."foundation_table" ("id" integer)"#
        )
        #expect(
            FoundationTable.$id.prepare(.psql).plain ==
                #""foundation_schema"."foundation_table"."id""#
        )
        #expect(
            reference.query.prepare(.psql).plain ==
                #"REFERENCES "foundation_schema"."foundation_table""#
        )
    }

    @Test("F20 plain table and Decodable paths remain unqualified")
    func plainTableCompatibility() {
        #expect(FoundationPlainTable.column("id").prepare(.psql).plain == #""plain_table"."id""#)
        #expect(FoundationPlainTable.table.prepare(.psql).plain == #""plain_table""#)
        #expect(FoundationPlainDecodable.table.prepare(.psql).plain == #""FoundationPlainDecodable""#)
    }
}
