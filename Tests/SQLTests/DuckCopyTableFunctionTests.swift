import Testing
@testable import SQL

private final class Task25IdentifierDialect: SQLDialect {
    override func catalogName(_ value: String) -> String { "CAT[\(value)]" }
    override func schemaName(_ value: String) -> String { "SCH[\(value)]" }
    override func tableName(_ value: String) -> String { "TAB[\(value)]" }
    override func column(_ value: String) -> String { "COL[\(value)]" }
}

private func task25CopyTarget() -> Path.Table {
    Path.Table("events")
}

private func task25Copy(_ table: Path.Table, to destination: SwifQLable) -> SwifQLable {
    SwifQL.copy(table, to: destination)
}

@Suite("Duck COPY and table-file functions")
struct DuckCopyTableFunctionTests: SwifQLTests {
    @Test("COPY table directions preserve native structure and binds")
    func copyTableDirections() {
        let table = task25CopyTarget()
        let to = SwifQL.copy(
            table,
            to: "events.csv",
            options: .format("csv"), .header
        )
        let from = SwifQL.copy(
            table,
            from: "events.csv",
            options: .format("csv"), .header
        )

        #expect(to.prepare(.duck).plain == "COPY \"events\" TO 'events.csv' (FORMAT 'csv', HEADER)")
        #expect(from.prepare(.duck).plain == "COPY \"events\" FROM ('events.csv') (FORMAT 'csv', HEADER)")

        let toPrepared = to.prepare(.duck).splitted
        #expect(toPrepared.query == "COPY \"events\" TO $1 (FORMAT $2, HEADER)")
        #expect(toPrepared.values.map { String(describing: $0) } == ["events.csv", "csv"])

        let fromPrepared = from.prepare(.duck).splitted
        #expect(fromPrepared.query == "COPY \"events\" FROM ($1) (FORMAT $2, HEADER)")
        #expect(fromPrepared.values.map { String(describing: $0) } == ["events.csv", "csv"])

        let fromExpression = SwifQL.copy(
            table,
            from: Fn.coalesce("events.csv", "fallback.csv"),
            options: .header
        )
        #expect(
            fromExpression.prepare(.duck).splitted.query ==
                "COPY \"events\" FROM (coalesce($1,$2)) (HEADER)"
        )
        #expect(fromExpression.prepare(.duck).splitted.values.map { String(describing: $0) } == ["events.csv", "fallback.csv"])
    }

    @Test("COPY query TO owns one parenthesized query and preserves child order")
    func copyQueryTo() {
        let table = task25CopyTarget()
        let query = SwifQL
            .select(table.column("id"))
            .from(table)
            .where(table.column("kind") == "open")
        let copy = SwifQL.copy(
            query: query,
            to: "events.parquet",
            options: .format("parquet"), .compression("zstd")
        )

        #expect(
            copy.prepare(.duck).plain ==
                "COPY (SELECT \"events\".\"id\" FROM \"events\" WHERE \"events\".\"kind\" = 'open') TO 'events.parquet' (FORMAT 'parquet', COMPRESSION 'zstd')"
        )

        let prepared = copy.prepare(.duck).splitted
        #expect(
            prepared.query ==
                "COPY (SELECT \"events\".\"id\" FROM \"events\" WHERE \"events\".\"kind\" = $1) TO $2 (FORMAT $3, COMPRESSION $4)"
        )
        #expect(prepared.values.map { String(describing: $0) } == ["open", "events.parquet", "parquet", "zstd"])
    }

    @Test("COPY FROM DATABASE catalogs and table targets are structural")
    func structuralCopyTargets() {
        let table = task25CopyTarget()
        let tableCopy = task25Copy(table, to: "events.csv")
        let databaseCopy = SwifQL.copy(
            fromDatabase: Path.Catalog("source catalog"),
            to: Path.Catalog("destination catalog"),
            options: .schema
        )

        #expect(table.parts.first is SwifQLPartTable)
        #expect(databaseCopy.parts.first is SwifQLStructuralFramePart)
        #expect(
            databaseCopy.prepare(.duck).plain ==
                "COPY FROM DATABASE \"source catalog\" TO \"destination catalog\" (SCHEMA)"
        )
        #expect(databaseCopy.prepare(.duck).splitted.values.isEmpty)
        #expect(tableCopy.prepare(.duck).splitted.values.count == 1)

        let frame = tableCopy.parts.first as? SwifQLStructuralFramePart
        #expect(frame?.children.contains { $0 is SwifQLPartTable } == true)
        #expect(frame?.children.contains { $0 is SwifQLPartUnsafeValue } == true)
    }

    @Test("All exposed COPY option conveniences render as open ordered options")
    func copyOptionMatrix() {
        let matrix: [(option: CopyOption, plain: String, split: String, value: String?)] = [
            (.format("parquet"), "FORMAT 'parquet'", "FORMAT $1", "parquet"),
            (.header, "HEADER", "HEADER", nil),
            (.header(true), "HEADER TRUE", "HEADER TRUE", nil),
            (.delimiter("|"), "DELIMITER '|'", "DELIMITER $1", "|"),
            (.compression("zstd"), "COMPRESSION 'zstd'", "COMPRESSION $1", "zstd"),
            (.null("NA"), "NULL 'NA'", "NULL $1", "NA"),
            (.array, "ARRAY", "ARRAY", nil),
            (.array(true), "ARRAY TRUE", "ARRAY TRUE", nil),
            (.rowGroupSize(128), "ROW_GROUP_SIZE 128", "ROW_GROUP_SIZE $2", "128"),
            (.compressionLevel(3), "COMPRESSION_LEVEL 3", "COMPRESSION_LEVEL $2", "3"),
            (.schema, "SCHEMA", "SCHEMA", nil)
        ]

        for entry in matrix {
            let query = SwifQL.copy(task25CopyTarget(), to: "out", options: [entry.option])
            #expect(query.prepare(.duck).plain == "COPY \"events\" TO 'out' (\(entry.plain))")
            let splitOption = entry.value == nil ? entry.split : entry.split.replacingOccurrences(of: "$1", with: "$2")
            #expect(query.prepare(.duck).splitted.query == "COPY \"events\" TO $1 (\(splitOption))")

            let expectedValues = entry.value.map { ["out", $0] } ?? ["out"]
            #expect(query.prepare(.duck).splitted.values.map { String(describing: $0) } == expectedValues)
        }

        let ordered = SwifQL.copy(
            task25CopyTarget(),
            to: "out",
            options: [
                .format("csv"),
                .delimiter("|"),
                .null("NA"),
                .compressionLevel(5)
            ]
        )
        #expect(
            ordered.prepare(.duck).plain ==
                "COPY \"events\" TO 'out' (FORMAT 'csv', DELIMITER '|', NULL 'NA', COMPRESSION_LEVEL 5)"
        )
        #expect(
            ordered.prepare(.duck).splitted.query ==
                "COPY \"events\" TO $1 (FORMAT $2, DELIMITER $3, NULL $4, COMPRESSION_LEVEL $5)"
        )
        #expect(ordered.prepare(.duck).splitted.values.map { String(describing: $0) } == ["out", "csv", "|", "NA", "5"])
    }

    @Test("CopyOption is structured, downstream-extensible, and expression-preserving")
    func openCopyOption() {
        let custom = CopyOption(
            name: CopyOption.Name("CUSTOM_FORMAT"),
            value: Fn.coalesce("left", "fallback")
        )
        let query = SwifQL.copy(task25CopyTarget(), to: "out", options: [custom])

        #expect(custom.name.rawValue == "CUSTOM_FORMAT")
        #expect(custom.value != nil)
        #expect(
            query.prepare(.duck).plain ==
                "COPY \"events\" TO 'out' (CUSTOM_FORMAT coalesce('left','fallback'))"
        )
        #expect(
            query.prepare(.duck).splitted.query ==
                "COPY \"events\" TO $1 (CUSTOM_FORMAT coalesce($2,$3))"
        )
        #expect(query.prepare(.duck).splitted.values.map { String(describing: $0) } == ["out", "left", "fallback"])
    }

    @Test("Table-function options use exact name-equals-value grammar")
    func tableFunctionOptionGrammar() {
        let custom = TableFunctionOption(
            name: TableFunctionOption.Name("custom_option"),
            value: Fn.coalesce("left", "fallback")
        )
        let scan = Fn.readCSV(
            "events.csv",
            options: .header(true), .delimiter("|"), .sampleSize(100), custom
        )

        #expect(custom.name.rawValue == "custom_option")
        #expect(
            scan.prepare(.duck).plain ==
                "read_csv('events.csv', header = TRUE, delim = '|', sample_size = 100, custom_option = coalesce('left','fallback'))"
        )
        #expect(
            scan.prepare(.duck).splitted.query ==
                "read_csv($1, header = TRUE, delim = $2, sample_size = $3, custom_option = coalesce($4,$5))"
        )
        #expect(scan.prepare(.duck).splitted.values.map { String(describing: $0) } == ["events.csv", "|", "100", "left", "fallback"])
        #expect(!scan.prepare(.duck).plain.contains(":="))
    }

    @Test("Exact table-file helpers compose through ordinary FROM")
    func exactTableFileHelpers() {
        let csv = Fn.readCSV("events.csv", options: .header(true), .delimiter("|"), .sampleSize(2))
        let parquet = Fn.readParquet(
            "events.parquet",
            options: .unionByName(true), .filename(true), .hivePartitioning(false)
        )
        let json = Fn.readJSON("events.json", options: .format("array"))
        let glob = Fn.glob("*.parquet")

        #expect(
            csv.prepare(.duck).plain ==
                "read_csv('events.csv', header = TRUE, delim = '|', sample_size = 2)"
        )
        #expect(
            parquet.prepare(.duck).plain ==
                "read_parquet('events.parquet', union_by_name = TRUE, filename = TRUE, hive_partitioning = FALSE)"
        )
        #expect(json.prepare(.duck).plain == "read_json('events.json', format = 'array')")
        #expect(glob.prepare(.duck).plain == "glob('*.parquet')")

        let from = SwifQL.select(SwifQL.asterisk).from(glob)
        #expect(from.prepare(.duck).plain == "SELECT * FROM glob('*.parquet')")
        #expect(from.prepare(.duck).splitted.query == "SELECT * FROM glob($1)")
        #expect(from.prepare(.duck).splitted.values.map { String(describing: $0) } == ["*.parquet"])

        let prepared = parquet.prepare(.duck).splitted
        #expect(
            prepared.query ==
                "read_parquet($1, union_by_name = TRUE, filename = TRUE, hive_partitioning = FALSE)"
        )
        #expect(prepared.values.map { String(describing: $0) } == ["events.parquet"])
    }

    @Test("COPY and table functions survive direct, erased, copied, helper, and conditional composition")
    func compositionInvariance() {
        let direct = SwifQL.copy(
            task25CopyTarget(),
            to: "events.csv",
            options: .format("csv")
        )
        let copied = SwifQLableParts(parts: direct.parts)
        let erased: SwifQLable = copied
        let helper = SwifQLableParts(parts: [SwifQLPartOperator.space, .custom("TAIL")])
        let composed = direct ~ helper
        let scan = Fn.readParquet("events.parquet", options: .unionByName(true))
        var conditional: SwifQLable = SwifQL
        if true {
            conditional = conditional.copy(task25CopyTarget(), from: "events.csv")
        }

        #expect(copied.prepare(.duck).plain == direct.prepare(.duck).plain)
        #expect(erased.prepare(.duck).plain == direct.prepare(.duck).plain)
        #expect(copied.prepare(.duck).splitted.query == direct.prepare(.duck).splitted.query)
        #expect(copied.prepare(.duck).splitted.values.map { String(describing: $0) } == ["events.csv", "csv"])
        #expect(composed.prepare(.duck).plain.contains("TAIL"))
        #expect(conditional.prepare(.duck).plain == "COPY \"events\" FROM ('events.csv')")

        let copiedScan = SwifQLableParts(parts: scan.parts)
        #expect(copiedScan.prepare(.duck).plain == scan.prepare(.duck).plain)
        #expect((copiedScan ~ helper).prepare(.duck).plain.contains("TAIL"))
    }

    @Test("Existing dialect hooks and historical composition remain untouched")
    func dialectAndCompatibility() {
        let custom = SwifQL.copy(
            task25CopyTarget(),
            to: "events.csv",
            options: .format("csv")
        )
        #expect(custom.prepare(Task25IdentifierDialect()).plain == "COPY TAB[events] TO 'events.csv' (FORMAT 'csv')")

        let historical = SwifQL.select(Fn.coalesce("x", "y")).from(task25CopyTarget())
        #expect(historical.prepare(.psql).plain == "SELECT coalesce('x','y') FROM \"events\"")
        #expect(historical.prepare(.mysql).plain == "SELECT coalesce('x','y') FROM events")
        #expect(historical.prepare(.duck).plain == "SELECT coalesce('x','y') FROM \"events\"")
    }
}
