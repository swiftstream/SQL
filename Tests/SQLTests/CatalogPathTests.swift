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
        #expect(Path.Catalog("analytics").prepare(.duck).plain == #""analytics""#)
        #expect(Path.Catalog("analytics").schema("main").prepare(.duck).plain == #""analytics"."main""#)
        #expect(Path.Catalog("analytics").schema("main").table("events").prepare(.duck).plain == #""analytics"."main"."events""#)
        #expect(Path.Catalog("analytics").schema("main").table("events").column("id").prepare(.duck).plain == #""analytics"."main"."events"."id""#)
    }

    @Test("Duck catalog paths quote reserved, Unicode, and embedded quote names")
    func identifierSafety() {
        let names = ["select", "данные", "event\"archive"]

        for name in names {
            let path = Path.Catalog(name)
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
        let oneChain = Path.Catalog("analytics")
            .schema("main")
            .table("events")
            .column("id")
        let helper = Path.Catalog("analytics").schema("main")
        let helperPath = helper.table(Path.Table("events")).column(Path.Column("id"))
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
    }

    @Test("Catalog parts and final key paths remain publicly inspectable")
    func publicRepresentation() {
        let catalog = Path.Catalog("analytics")
        let catalogPart = catalog.parts.first as? SwifQLPartCatalog
        #expect(catalogPart?.name == "analytics")

        let path = catalog.schema("main").table("events").column("id")
        let lastPath: KeyPathLastPath = path
        #expect(lastPath.lastPath == "id")
    }

    @Test("Catalog rendering delegates to additive dialect hook")
    func dialectHook() {
        #expect(Path.Catalog("analytics").prepare(CatalogDialect()).plain == "CATALOG[analytics]")
    }

    @Test("Existing no-catalog paths retain PostgreSQL and MySQL SQL")
    func legacyPaths() {
        check(
            Path.Table("events").column("id"),
            .psql(#""events"."id""#),
            .mysql("events.id")
        )
        check(
            Path.Schema("main").table("events").column("id"),
            .psql(#""main"."events"."id""#),
            .mysql("main.events.id")
        )
    }
}
