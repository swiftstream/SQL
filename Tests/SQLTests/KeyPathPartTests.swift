import Testing
@testable import SQL

@Suite("Key-path part")
struct KeyPathPartTests {
    @Test("Legacy initializer defaults and catalog values are preserved")
    func initializersPreserveLegacyDefaultsAndStoreCatalog() {
        let legacyVariadic = SQLPartKeyPath(schema: "main", table: "events", paths: "payload", "field")
        let legacyArray = SQLPartKeyPath(schema: "main", table: "events", paths: ["payload", "field"], asText: true)
        let catalogVariadic = SQLPartKeyPath(catalog: "warehouse", schema: "analytics", table: "events", paths: "payload", "field", asText: true)
        let catalogArray = SQLPartKeyPath(catalog: "warehouse", schema: "analytics", table: "events", paths: ["payload", "field"])

        #expect(legacyVariadic.catalog == nil)
        #expect(legacyArray.catalog == nil)
        #expect(legacyVariadic.paths == ["payload", "field"])
        #expect(legacyArray.asText)
        #expect(catalogVariadic.catalog == "warehouse")
        #expect(catalogVariadic.schema == "analytics")
        #expect(catalogVariadic.table == "events")
        #expect(catalogVariadic.paths == ["payload", "field"])
        #expect(catalogVariadic.asText)
        #expect(catalogArray.catalog == "warehouse")
        #expect(!catalogArray.asText)
    }

    @Test("Catalog column path is one semantic part")
    func catalogColumnPathIsOneSemanticPart() {
        let path = Path.Catalog("warehouse")
            .schema("analytics")
            .table("events")
            .column("payload", "field")

        #expect(path.parts.count == 1)
        let keyPath = path.parts.first as? SQLPartKeyPath
        #expect(keyPath?.catalog == "warehouse")
        #expect(keyPath?.schema == "analytics")
        #expect(keyPath?.table == "events")
        #expect(keyPath?.paths == ["payload", "field"])
        #expect(keyPath?.asText == false)
    }

    @Test("Column projection uses only the first path")
    func columnProjectionUsesOnlyFirstPath() {
        let keyPath = SQLPartKeyPath(
            catalog: "warehouse",
            schema: "analytics",
            table: "events",
            paths: ["payload", "field"]
        )

        #expect(keyPath.column.name == "payload")
    }

    @Test("Items projection drops qualification and uses the first path")
    func itemsProjectionDropsQualificationAndUsesFirstPath() {
        let keyPath = Path.Catalog("warehouse")
            .schema("analytics")
            .table("events")
            .column("payload", "field")
        let query = SQLableParts(parts: SQLPartOperator("SELECT"))
            .items(keyPath)

        #expect(query.prepare(.psql).plain == #"SELECT "payload""#)
        #expect(query.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("Terminal name projections use the last path")
    func terminalNameProjectionsUseLastPath() {
        let keyPath = Path.Catalog("warehouse")
            .schema("analytics")
            .table("events")
            .column("payload", "field")
        let fields = SQLableParts(parts: SQLPartOperator("INSERT INTO records")).fields(
            keyPath
        )
        let using = From {
            Path.Table("left_events")
            Join(.inner, Path.Table("right_events"))
            Using(keyPath)
        }

        #expect(fields.prepare(.psql).plain == #"INSERT INTO records ("field")"#)
        #expect(using.prepare(.psql).plain == #"FROM "left_events" INNER JOIN "right_events" USING ("field")"#)
    }

    @Test("Catalog-qualified single-column subscript keeps direct PostgreSQL grouping")
    func catalogQualifiedSingleColumnSubscriptKeepsDirectPostgresGrouping() {
        let keyPath = SQLPartKeyPath(
            catalog: "warehouse",
            schema: "analytics",
            table: "events",
            paths: ["payload"]
        )
        let expression = SQLableParts(parts: keyPath)[2]
        let prepared = expression.prepare(.psql)

        #expect(prepared.plain == #""warehouse"."analytics"."events"."payload"[2]"#)
        #expect(prepared.splitted.query == #""warehouse"."analytics"."events"."payload"[$1]"#)
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? Int == 2)
    }

    @Test("Qualified key path does not contribute binds")
    func qualifiedKeyPathDoesNotContributeBinds() {
        let keyPath = SQLPartKeyPath(
            catalog: "warehouse",
            schema: "analytics",
            table: "events",
            paths: ["payload", "field"],
            asText: true
        )
        let prepared = SQLableParts(parts: keyPath).prepare(.psql)

        #expect(prepared.plain == #""warehouse"."analytics"."events"."payload"->>'field'"#)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("Observed qualified path keeps following bind in order")
    func observedQualifiedPathKeepsFollowingBindInOrder() {
        let keyPath = SQLPartKeyPath(
            catalog: "warehouse",
            schema: "analytics",
            table: "events",
            paths: ["payload", "field"],
            asText: true
        )
        let query = SQLableParts(parts: [
            keyPath,
            SQLPartOperator(","),
            SQLPartUnsafeValue("after")
        ])
        let ordinary = query.prepare(.psql)
        let observed = query.prepareObservingUnsafeValues(.psql)

        #expect(observed.prepared.plain == ordinary.plain)
        #expect(observed.prepared.splitted.query == ordinary.splitted.query)
        #expect(observed.prepared.splitted.query == #""warehouse"."analytics"."events"."payload"->>'field',$1"#)
        #expect(observed.prepared.splitted.values.count == 1)
        #expect(observed.prepared.splitted.values[0] as? String == "after")
        if case .complete(let occurrences) = observed.unsafeValueTrace {
            #expect(occurrences.count == 1)
            #expect(occurrences.first?.value as? String == "after")
            #expect(occurrences.first?.disposition == .bound(index: 0))
        } else {
            Issue.record("Expected a complete unsafe-value trace")
        }
    }
}
