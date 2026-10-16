@testable import SQL
import Testing

@Suite("Catalog path composition")
struct CatalogPathTests: SwifQLTests {
    private final class CatalogDialect: SQLDialect {
        override func catalogName(_ value: String) -> String {
            "CATALOG[\(value)]"
        }
    }

    @Test("Duck renders each catalog path level")
    func pathLevels() {
        #expect(DB.Catalog("analytics").prepare(.duck).plain == #""analytics""#)
        #expect(DB.Catalog("analytics").schema("main").prepare(.duck).plain == #""analytics"."main""#)
        #expect(DB.Catalog("analytics").schema("main").table("events").prepare(.duck).plain == #""analytics"."main"."events""#)
        #expect(DB.Catalog("analytics").schema("main").table("events").column("id").prepare(.duck).plain == #""analytics"."main"."events"."id""#)
    }

    @Test("Duck catalog paths quote reserved, Unicode, and embedded quote names")
    func identifierSafety() {
        let names = ["select", "данные", "event\"archive"]

        for name in names {
            let path = DB.Catalog(name)
                .schema(name)
                .table(name)
                .column(name)
            let escaped = name.replacingOccurrences(of: "\"", with: "\"\"")
            let quoted = "\"\(escaped)\""

            #expect(path.prepare(.duck).plain == [quoted, quoted, quoted, quoted].joined(separator: "."))
        }
    }

    @Test("Catalog prefixes survive copied parts and helper composition")
    func composition() {
        let oneChain = DB.Catalog("analytics")
            .schema("main")
            .table("events")
            .column("id")
        let helper = DB.Catalog("analytics").schema("main")
        let helperPath = helper.table(DB.Table("events")).column(DB.Column("id"))
        let copied = SwifQLableParts(parts: oneChain.parts)

        #expect(helperPath.prepare(.duck).plain == oneChain.prepare(.duck).plain)
        #expect(copied.prepare(.duck).plain == oneChain.prepare(.duck).plain)
        #expect(copied.parts.count == 1)

        let keyPath = copied.parts.first as? SwifQLPartKeyPath
        #expect(keyPath?.catalog == "analytics")
        #expect(keyPath?.schema == "main")
        #expect(keyPath?.table == "events")
        #expect(keyPath?.paths == ["id"])

        #expect(oneChain.prepare(.psql).plain == #""analytics"."main"."events"."id""#)
        #expect(oneChain.prepare(.duck).plain == #""analytics"."main"."events"."id""#)
        #expect(oneChain.prepare(.mysql).plain == "analytics.main.events.id")

        let relation = DB.Catalog("analytics").schema("main").table("events")
        #expect(relation.parts.count == 1)
        let relationPart = relation.parts.first as? SQLPartTable
        #expect(relationPart?.catalog == "analytics")
        #expect(relationPart?.schema == "main")
        #expect(relationPart?.table == "events")
        #expect(relation.prepare(.psql).plain == #""analytics"."main"."events""#)
    }

    @Test("Catalog parts and final key paths remain publicly inspectable")
    func publicRepresentation() {
        let catalog = DB.Catalog("analytics")
        let catalogPart = catalog.parts.first as? SQLPartCatalog
        #expect(catalogPart?.name == "analytics")

        let path = catalog.schema("main").table("events").column("id")
        let lastPath: KeyPathLastPath = path
        #expect(lastPath.lastPath == "id")
    }

    @Test("Catalog rendering delegates to additive dialect hook")
    func dialectHook() {
        #expect(DB.Catalog("analytics").prepare(CatalogDialect()).plain == "CATALOG[analytics]")
    }

    @Test("Existing no-catalog paths retain PostgreSQL and MySQL SQL")
    func legacyPaths() {
        check(
            DB.Table("events").column("id"),
            .psql(#""events"."id""#),
            .mysql("events.id")
        )
        check(
            DB.Schema("main").table("events").column("id"),
            .psql(#""main"."events"."id""#),
            .mysql("main.events.id")
        )
    }
}
