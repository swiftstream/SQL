import Foundation
import Testing
@testable import SQL

private final class Task24CatalogDialect: SQLDialect {
    override func catalogName(_ value: String) -> String { "CAT[\(value)]" }
    override func schemaName(_ value: String) -> String { "SCH[\(value)]" }
    override func tableName(_ value: String) -> String { "TAB[\(value)]" }
    override func column(_ value: String) -> String { "COL[\(value)]" }
    override func alias(_ value: String) -> String { "ALS[\(value)]" }
    override func identifier(_ value: String) -> String { "ID[\(value)]" }
}

private func task24Attach(_ source: String) -> SwifQLable {
    SwifQL.attach(
        source,
        mode: .ifNotExists,
        as: Path.Catalog("analytics")
    )
}

@Suite("Duck ATTACH, DETACH, and USE")
struct DuckAttachCatalogTests: SwifQLTests {
    @Test("ATTACH modes, aliases, and ordered options render exactly")
    func attachModesAliasesAndOptions() {
        let catalog = Path.Catalog("analytics")
        let basic = SwifQL.attach("file.duckdb")
        let ifNotExists = SwifQL.attach(
            "file.duckdb",
            mode: .ifNotExists,
            as: catalog
        )
        let orReplace = SwifQL.attach(
            "file.duckdb",
            mode: .orReplace,
            as: catalog,
            options: .compress("true"),
                .blockSize(16_384)
        )

        #expect(basic.prepare(.duck).plain == "ATTACH 'file.duckdb'")
        #expect(ifNotExists.prepare(.duck).plain == "ATTACH IF NOT EXISTS 'file.duckdb' AS \"analytics\"")
        #expect(
            orReplace.prepare(.duck).plain ==
                "ATTACH OR REPLACE 'file.duckdb' AS \"analytics\" (COMPRESS 'true', BLOCK_SIZE 16384)"
        )

        let prepared = orReplace.prepare(.duck).splitted
        #expect(
            prepared.query ==
                "ATTACH OR REPLACE 'file.duckdb' AS \"analytics\" (COMPRESS $1, BLOCK_SIZE $2)"
        )
        #expect(prepared.values.map { String(describing: $0) } == ["true", "16384"])

        let arrayOptions = SwifQL.attach(
            "file.duckdb",
            as: catalog,
            options: [.readOnly, .rowGroupSize(2_048)]
        )
        #expect(
            arrayOptions.prepare(.duck).plain ==
                "ATTACH 'file.duckdb' AS \"analytics\" (READ_ONLY, ROW_GROUP_SIZE 2048)"
        )
    }

    @Test("All built-in ATTACH option conveniences map exactly and bind normally")
    func allBuiltInAttachOptions() {
        let matrix: [(option: AttachOption, token: String, hasValue: Bool, plainValue: String?, value: String?)] = [
            (.readOnly, "READ_ONLY", false, nil, nil),
            (.compress("true"), "COMPRESS", true, "'true'", "true"),
            (.type("duckdb"), "TYPE", true, "'duckdb'", "duckdb"),
            (.defaultTable("default_table"), "DEFAULT_TABLE", true, "'default_table'", "default_table"),
            (.blockSize(16_384), "BLOCK_SIZE", true, "16384", "16384"),
            (.rowGroupSize(2_048), "ROW_GROUP_SIZE", true, "2048", "2048"),
            (.storageVersion("v1.0.0"), "STORAGE_VERSION", true, "'v1.0.0'", "v1.0.0"),
            (.encryptionKey("task24-key"), "ENCRYPTION_KEY", true, "'task24-key'", "task24-key"),
            (.encryptionCipher("GCM"), "ENCRYPTION_CIPHER", true, "'GCM'", "GCM"),
            (.recoveryMode("no_wal_writes"), "RECOVERY_MODE", true, "'no_wal_writes'", "no_wal_writes")
        ]

        for entry in matrix {
            #expect((entry.option.value != nil) == entry.hasValue)

            let query = SwifQL.attach("file.duckdb", options: [entry.option])
            let plainOption = entry.plainValue.map { "\(entry.token) \($0)" } ?? entry.token
            #expect(query.prepare(.duck).plain == "ATTACH 'file.duckdb' (\(plainOption))")

            let prepared = query.prepare(.duck).splitted
            let splitOption = entry.value.map { _ in "\(entry.token) $1" } ?? entry.token
            #expect(prepared.query == "ATTACH 'file.duckdb' (\(splitOption))")
            #expect(prepared.values.map { String(describing: $0) } == (entry.value.map { [$0] } ?? []))
        }

        let allOptions: [AttachOption] = [
            .readOnly,
            .compress("true"),
            .type("duckdb"),
            .defaultTable("default_table"),
            .blockSize(16_384),
            .rowGroupSize(2_048),
            .storageVersion("v1.0.0"),
            .encryptionKey("task24-key"),
            .encryptionCipher("GCM"),
            .recoveryMode("no_wal_writes")
        ]
        let query = SwifQL.attach("file.duckdb", options: allOptions)
        #expect(
            query.prepare(.duck).plain ==
                "ATTACH 'file.duckdb' (READ_ONLY, COMPRESS 'true', TYPE 'duckdb', DEFAULT_TABLE 'default_table', BLOCK_SIZE 16384, ROW_GROUP_SIZE 2048, STORAGE_VERSION 'v1.0.0', ENCRYPTION_KEY 'task24-key', ENCRYPTION_CIPHER 'GCM', RECOVERY_MODE 'no_wal_writes')"
        )

        let prepared = query.prepare(.duck).splitted
        #expect(
            prepared.query ==
                "ATTACH 'file.duckdb' (READ_ONLY, COMPRESS $1, TYPE $2, DEFAULT_TABLE $3, BLOCK_SIZE $4, ROW_GROUP_SIZE $5, STORAGE_VERSION $6, ENCRYPTION_KEY $7, ENCRYPTION_CIPHER $8, RECOVERY_MODE $9)"
        )
        #expect(
            prepared.values.map { String(describing: $0) } ==
                ["true", "duckdb", "default_table", "16384", "2048", "v1.0.0", "task24-key", "GCM", "no_wal_writes"]
        )
    }

    @Test("Source values and catalog aliases keep distinct part semantics")
    func sourceAndAliasParts() {
        let alias = Path.Catalog("данные")
        let source: String = "source.duckdb"
        let query = SwifQL.attach(source, as: alias)
        let frame = query.parts.first as? SwifQLStructuralFramePart
        let children = frame?.children ?? []

        #expect(children.contains { $0 is SwifQLPartSafeValue })
        #expect(!children.contains { $0 is SwifQLPartUnsafeValue })
        #expect(children.contains { $0 is SwifQLPartCatalog })
        #expect(alias.parts.first is SwifQLPartCatalog)
        #expect(query.prepare(.duck).plain == "ATTACH 'source.duckdb' AS \"данные\"")
        #expect(query.prepare(.duck).splitted.query == "ATTACH 'source.duckdb' AS \"данные\"")
        #expect(query.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Dynamic ATTACH String sources escape apostrophes and remain bind-free")
    func dynamicStringSourceEscaping() {
        let source = "o'clock.duckdb"
        let query = SwifQL.attach(source, as: Path.Catalog("quoted"))
        let frame = query.parts.first as? SwifQLStructuralFramePart
        let children = frame?.children ?? []

        #expect(children.contains { $0 is SwifQLPartSafeValue })
        #expect(!children.contains { $0 is SwifQLPartUnsafeValue })
        #expect(query.prepare(.duck).plain == "ATTACH 'o''clock.duckdb' AS \"quoted\"")
        #expect(query.prepare(.duck).splitted.query == "ATTACH 'o''clock.duckdb' AS \"quoted\"")
        #expect(query.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("AttachOption is open, structured, ordered, and expression-preserving")
    func openAttachOptions() {
        let custom = AttachOption(
            name: AttachOption.Name("CUSTOM_OPTION"),
            value: Fn.coalesce("primary", "fallback")
        )
        let query = SwifQL.attach(
            "file.duckdb",
            as: Path.Catalog("analytics"),
            options: [custom, .encryptionCipher("GCM")]
        )

        #expect(custom.name.rawValue == "CUSTOM_OPTION")
        #expect(custom.value != nil)
        #expect(
            query.prepare(.duck).plain ==
                "ATTACH 'file.duckdb' AS \"analytics\" (CUSTOM_OPTION coalesce('primary','fallback'), ENCRYPTION_CIPHER 'GCM')"
        )
        let prepared = query.prepare(.duck).splitted
        #expect(
            prepared.query ==
                "ATTACH 'file.duckdb' AS \"analytics\" (CUSTOM_OPTION coalesce($1,$2), ENCRYPTION_CIPHER $3)"
        )
        #expect(prepared.values.map { String(describing: $0) } == ["primary", "fallback", "GCM"])
    }

    @Test("DETACH and all three USE targets are structural and bind-free")
    func detachAndUseTargets() {
        let catalog = SwifQL.detach(Path.Catalog("select\"catalog"))
        let catalogUse = SwifQL.use(Path.Catalog("данные"))
        let schemaUse = SwifQL.use(Path.Schema("reporting"))
        let catalogSchemaUse = SwifQL.use(Path.Catalog("analytics").schema("main"))

        #expect(catalog.prepare(.duck).plain == "DETACH \"select\"\"catalog\"")
        #expect(catalogUse.prepare(.duck).plain == "USE \"данные\"")
        #expect(schemaUse.prepare(.duck).plain == "USE \"reporting\"")
        #expect(catalogSchemaUse.prepare(.duck).plain == "USE \"analytics\".\"main\"")

        for query in [catalog, catalogUse, schemaUse, catalogSchemaUse] {
            let prepared = query.prepare(.duck).splitted
            #expect(prepared.query == query.prepare(.duck).plain)
            #expect(prepared.values.isEmpty)
        }
    }

    @Test("ATTACH, DETACH, and USE survive direct, erased, copied, helper, and conditional composition")
    func compositionInvariance() {
        let direct = task24Attach("file.duckdb")
        let copied = SwifQLableParts(parts: direct.parts)
        let erased: SwifQLable = copied
        let helper = SwifQLableParts(parts: [SwifQLPartOperator.space, .custom("TAIL")])
        let composed = direct ~ helper

        var conditional: SwifQLable = SwifQL
        if true {
            conditional = conditional.attach("conditional.duckdb", as: Path.Catalog("conditional"))
        }

        #expect(copied.prepare(.duck).plain == direct.prepare(.duck).plain)
        #expect(erased.prepare(.duck).plain == direct.prepare(.duck).plain)
        #expect(copied.prepare(.duck).splitted.query == direct.prepare(.duck).splitted.query)
        #expect(copied.prepare(.duck).splitted.values.isEmpty)
        #expect(erased.prepare(.duck).splitted.query == direct.prepare(.duck).splitted.query)
        #expect(erased.prepare(.duck).splitted.values.isEmpty)
        #expect(composed.prepare(.duck).plain.contains("TAIL"))
        #expect(conditional.prepare(.duck).plain == "ATTACH 'conditional.duckdb' AS \"conditional\"")
        #expect(SwifQL.detach(Path.Catalog("analytics")).prepare(.duck).splitted.values.isEmpty)
    }

    @Test("Catalog, schema, table, alias, and identifier hooks stay distinct")
    func dialectHooksAndCatalogPaths() {
        let dialect = Task24CatalogDialect()
        let attach = SwifQL.attach("file.duckdb", as: Path.Catalog("analytics"))
        let detach = SwifQL.detach(Path.Catalog("analytics"))
        let use = SwifQL.use(Path.Catalog("analytics").schema("main"))
        let path = Path.Catalog("analytics").schema("main").table("events").column("id")

        #expect(attach.prepare(dialect).plain == "ATTACH 'file.duckdb' AS CAT[analytics]")
        #expect(detach.prepare(dialect).plain == "DETACH CAT[analytics]")
        #expect(use.prepare(dialect).plain == "USE CAT[analytics].SCH[main]")
        #expect(path.prepare(.duck).plain == "\"analytics\".\"main\".\"events\".\"id\"")
    }

    @Test("Historical PostgreSQL and MySQL rendering remains unchanged")
    func historicalDialects() {
        check(
            SwifQL.attach("file.duckdb", as: Path.Catalog("analytics")),
            .psql("ATTACH 'file.duckdb' AS \"analytics\""),
            .mysql("ATTACH 'file.duckdb' AS analytics")
        )
        check(
            SwifQL.detach(Path.Catalog("analytics")),
            .psql("DETACH \"analytics\""),
            .mysql("DETACH analytics")
        )
        check(
            SwifQL.use(Path.Catalog("analytics").schema("main")),
            .psql("USE \"analytics\".\"main\""),
            .mysql("USE analytics.main")
        )
    }
}
