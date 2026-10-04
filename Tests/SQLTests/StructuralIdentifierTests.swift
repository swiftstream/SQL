import Testing
@testable import SQL

private final class MarkerIdentifierDialect: SQLDialect {
    override func catalogName(_ value: String) -> String { "CAT[\(value)]" }
    override func schemaName(_ value: String) -> String { "SCH[\(value)]" }
    override func tableName(_ value: String) -> String { "TAB[\(value)]" }
    override func column(_ value: String) -> String { "COL[\(value)]" }
    override func alias(_ value: String) -> String { "ALS[\(value)]" }
    override func identifier(_ value: String) -> String { "ID[\(value)]" }
}

private final class LegacyIdentifierDialect: SQLDialect {
    override func tableName(_ value: String) -> String { "legacy-table[\(value)]" }
}

@Suite("Structural identifiers")
struct StructuralIdentifierTests: SwifQLTests {
    @Test("All semantic identifier hooks remain independently extensible")
    func distinctSemanticHooks() {
        let parts = SwifQLableParts(parts: [
            SwifQLPartCatalog("catalog"),
            SwifQLPartOperator.period,
            SwifQLPartSchema("schema"),
            SwifQLPartOperator.period,
            SwifQLPartTable("table"),
            SwifQLPartOperator.period,
            SwifQLPartColumn("column"),
            SwifQLPartOperator.period,
            SwifQLPartAlias("alias"),
            SwifQLPartOperator.period,
            SwifQLPartIdentifier("identifier")
        ])

        #expect(
            parts.prepare(MarkerIdentifierDialect()).plain ==
                "CAT[catalog].SCH[schema].TAB[table].COL[column].ALS[alias].ID[identifier]"
        )
    }

    @Test("Qualifiers use catalog/schema hooks and the terminal uses only identifier")
    func qualifierAndTerminalOwnership() {
        let identifier = Path.Identifier(catalog: "memory", schema: "analytics", name: "report")
        #expect(
            identifier.prepare(MarkerIdentifierDialect()).plain ==
                "CAT[memory].SCH[analytics].ID[report]"
        )
        #expect((identifier as Any) is KeyPathLastPath == false)
        #expect(identifier.parts.count == 5)
        #expect(identifier.parts[0] is SwifQLPartCatalog)
        #expect(identifier.parts[2] is SwifQLPartSchema)
        #expect(identifier.parts[4] is SwifQLPartIdentifier)
        #expect(identifier.parts.contains { $0 is SwifQLPartTable } == false)
        #expect(identifier.parts.contains { $0 is SwifQLPartColumn } == false)
        #expect(identifier.parts.contains { $0 is SwifQLPartAlias } == false)
    }

    @Test("Identifier paths are value-semantic across copied and erased composition")
    func copiedAndErasedIdentity() {
        let original = Path.Identifier(schema: "analytics", name: "report")
        let copied = original
        let erased: SwifQLable = copied
        let rebuilt = SwifQLableParts(parts: copied.parts)

        #expect(copied.catalog == original.catalog)
        #expect(copied.schema == original.schema)
        #expect(copied.name == original.name)
        #expect((copied.parts.last as? SwifQLPartIdentifier)?.name == "report")
        #expect(erased.prepare(.duck).plain == #""analytics"."report""#)
        #expect(rebuilt.prepare(.duck).plain == erased.prepare(.duck).plain)
    }

    @Test("Legacy dialects compile without an identifier override")
    func legacyDialectCompatibility() {
        let identifier = Path.Identifier("report")
        #expect(identifier.prepare(LegacyIdentifierDialect()).plain == "report")
        #expect(Path.Table("events").prepare(LegacyIdentifierDialect()).plain == "legacy-table[events]")
    }

    @Test("PostgreSQL, MySQL, and Duck escape only the new identifier category")
    func dialectEscaping() {
        let tick = String(UnicodeScalar(96)!)
        let identifier = Path.Identifier("select\"" + tick + "name")
        let expectedQuoted = "\"select\"\"" + tick + "name\""
        let expectedMySQL = tick + "select\"" + tick + tick + "name" + tick

        #expect(identifier.prepare(.psql).plain == expectedQuoted)
        #expect(identifier.prepare(.mysql).plain == expectedMySQL)
        #expect(identifier.prepare(.duck).plain == expectedQuoted)
        #expect(identifier.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Unicode and whitespace terminal identifiers stay exact and bind-free")
    func unicodeAndWhitespaceEscaping() {
        let unicode = Path.Identifier("名字")
        let whitespace = Path.Identifier("report name")

        #expect(unicode.prepare(.psql).plain == #""名字""#)
        #expect(unicode.prepare(.mysql).plain == "`名字`")
        #expect(unicode.prepare(.duck).plain == #""名字""#)
        #expect(whitespace.prepare(.psql).plain == #""report name""#)
        #expect(whitespace.prepare(.mysql).plain == "`report name`")
        #expect(whitespace.prepare(.duck).plain == #""report name""#)

        #expect(unicode.prepare(.psql).splitted.values.isEmpty)
        #expect(unicode.prepare(.mysql).splitted.values.isEmpty)
        #expect(unicode.prepare(.duck).splitted.values.isEmpty)
        #expect(whitespace.prepare(.psql).splitted.values.isEmpty)
        #expect(whitespace.prepare(.mysql).splitted.values.isEmpty)
        #expect(whitespace.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Existing table and column paths keep their established output")
    func historicalPathOutput() {
        let query = SwifQL.select(Path.Table("events").column("id"))
        #expect(query.prepare(.psql).plain == #"SELECT "events"."id""#)
        #expect(query.prepare(.mysql).plain == "SELECT events.id")
        #expect(query.prepare(.duck).plain == #"SELECT "events"."id""#)
    }
}
