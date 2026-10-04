@testable import SQL
import Testing

@Suite("Fn camelCase compatibility")
struct FnCamelCaseCompatibilityTests {
    private func expectEquivalent(
        _ canonical: SwifQLable,
        _ legacy: SwifQLable,
        expected: String,
        dialect: SQLDialect = .psql
    ) {
        let canonicalSQL = SwifQL.select(canonical).prepare(dialect).plain
        let legacySQL = SwifQL.select(legacy).prepare(dialect).plain
        #expect(canonicalSQL == expected)
        #expect(legacySQL == expected)
        #expect(canonicalSQL == legacySQL)
    }

    @Test("Shared zero-argument Fn alias")
    func sharedZeroArgumentAlias() {
        expectEquivalent(
            Fn.rowNumber(),
            Fn.row_number(),
            expected: "SELECT row_number()"
        )
    }

    @Test("Shared variadic and array Fn aliases")
    func sharedVariadicAndArrayAliases() {
        expectEquivalent(
            Fn.arrayRemove(PgArray(1, 2, 3, 2), 2),
            Fn.array_remove(PgArray(1, 2, 3, 2), 2),
            expected: "SELECT array_remove(ARRAY[1, 2, 3, 2], 2)"
        )

        let items: [SwifQLable] = [PgArray(1, 2, 3, 2), 2]
        expectEquivalent(
            Fn.arrayRemove(items),
            Fn.array_remove(items),
            expected: "SELECT array_remove(ARRAY[1, 2, 3, 2], 2)"
        )
    }

    @Test("PostgreSQL JSON variadic and array aliases")
    func postgreSQLJSONVariadicAndArrayAliases() {
        expectEquivalent(
            Fn.jsonBuildArray("one", 2),
            Fn.json_build_array("one", 2),
            expected: "SELECT json_build_array('one', 2)"
        )

        let items: [SwifQLable] = ["one", 2]
        expectEquivalent(
            Fn.jsonBuildArray(items),
            Fn.json_build_array(items),
            expected: "SELECT json_build_array('one', 2)"
        )
    }

    @Test("PostgreSQL JSON path aliases preserve labels")
    func postgreSQLJSONPathAliases() {
        let json = #"{"f4":{"f6":"foo"}}"#
        let path = ["f4", "f6"]
        expectEquivalent(
            Fn.jsonExtractPath(json, pathElems: path),
            Fn.json_extract_path(json, path_elems: path),
            expected: #"SELECT json_extract_path('{"f4":{"f6":"foo"}}', 'f4', 'f6')"#
        )
    }

    @Test("PostgreSQL time default argument alias")
    func postgreSQLTimeDefaultArgumentAlias() {
        expectEquivalent(
            Fn.makeInterval(days: 10),
            Fn.make_interval(days: 10),
            expected: "SELECT make_interval(days => 10)"
        )
    }

    @Test("PostgreSQL generateSeries alias")
    func postgreSQLGenerateSeriesAlias() {
        expectEquivalent(
            Fn.generateSeries(1, 4),
            Fn.generate_series(1, 4),
            expected: "SELECT generate_series(1, 4)"
        )
    }

    @Test("PostgreSQL JSONB representative alias")
    func postgreSQLJSONBRepresentativeAlias() {
        expectEquivalent(
            Fn.jsonbBuildArray("one", 2),
            Fn.jsonb_build_array("one", 2),
            expected: "SELECT jsonb_build_array('one', 2)"
        )
    }

    @Test("MySQL Fn aliases")
    func mySQLAliases() {
        expectEquivalent(
            Fn.fromUnixTime(123),
            Fn.from_unixtime(123),
            expected: "SELECT FROM_UNIXTIME(123)",
            dialect: .mysql
        )
        expectEquivalent(
            Fn.dateFormat(CarBrands.column("createdAt"), "%y-%m"),
            Fn.date_format(CarBrands.column("createdAt"), "%y-%m"),
            expected: "SELECT DATE_FORMAT(CarBrands.createdAt, '%y-%m')",
            dialect: .mysql
        )
    }

    @Test("Base64 uses the canonical camelCase API")
    func base64CanonicalAPI() {
        #expect(
            SwifQL.select(Fn.fromBase64("SGVsbG8=")).prepare(.duck).plain
                == "SELECT from_base64('SGVsbG8=')"
        )
        #expect(
            SwifQL.select(Fn.fromBase64("SGVsbG8=")).prepare(.mysql).plain
                == "SELECT FROM_BASE64('SGVsbG8=')"
        )
    }
}

@Suite("Fn SQL-shaped naming compatibility")
struct FnSQLShapedNamingCompatibilityTests {
    private enum BindKind: Equatable {
        case string
        case int
        case double
        case bool
    }

    private enum TypedBind: Equatable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)

        var kind: BindKind {
            switch self {
            case .string: return .string
            case .int: return .int
            case .double: return .double
            case .bool: return .bool
            }
        }
    }

    private func typedBind(_ value: Encodable) -> TypedBind? {
        switch value {
        case let value as String: return .string(value)
        case let value as Int: return .int(value)
        case let value as Double: return .double(value)
        case let value as Bool: return .bool(value)
        default: return nil
        }
    }

    private func expectEquivalent(
        _ canonical: SwifQLable,
        _ legacy: SwifQLable,
        expected: String,
        dialect: SQLDialect = .psql
    ) {
        let canonicalPrepared = SwifQL.select(canonical).prepare(dialect)
        let legacyPrepared = SwifQL.select(legacy).prepare(dialect)
        #expect(canonicalPrepared.plain == expected)
        #expect(legacyPrepared.plain == expected)
        #expect(canonicalPrepared.plain == legacyPrepared.plain)
        #expect(canonicalPrepared.splitted.query == legacyPrepared.splitted.query)

        let canonicalValues = canonicalPrepared.splitted.values
        let legacyValues = legacyPrepared.splitted.values
        #expect(canonicalValues.count == legacyValues.count)
        guard canonicalValues.count == legacyValues.count else { return }

        for index in canonicalValues.indices {
            guard let canonicalBind = typedBind(canonicalValues[index]) else {
                Issue.record(
                    "Unexpected canonical bind type at ordered index \(index); supported bind types are String, Int, Double, and Bool"
                )
                return
            }
            guard let legacyBind = typedBind(legacyValues[index]) else {
                Issue.record(
                    "Unexpected legacy bind type at ordered index \(index); supported bind types are String, Int, Double, and Bool"
                )
                return
            }

            #expect(canonicalBind.kind == legacyBind.kind)
            #expect(canonicalBind == legacyBind)
        }
    }

    @Test("Canonical Fn and Fn.Name spellings preserve direct historical bridges")
    func directHistoricalBridges() {
        expectEquivalent(Fn.subStr("abcdef", 2), Fn.substr("abcdef", 2), expected: "SELECT substr('abcdef', 2)")
        expectEquivalent(Fn.setSeed(0.5), Fn.setseed(0.5), expected: "SELECT setseed(0.5)")
        expectEquivalent(Fn.bTrim("hello", "ll"), Fn.btrim("hello", "ll"), expected: "SELECT btrim('hello', 'll')")
        expectEquivalent(Fn.initCap("hello"), Fn.initcap("hello"), expected: "SELECT initcap('hello')")
        expectEquivalent(Fn.lPad("hello", 3, "lo"), Fn.lpad("hello", 3, "lo"), expected: "SELECT lpad('hello', 3, 'lo')")
        expectEquivalent(Fn.lTrim("hello", "he"), Fn.ltrim("hello", "he"), expected: "SELECT ltrim('hello', 'he')")
        expectEquivalent(Fn.rPad("hello", 3, "lo"), Fn.rpad("hello", 3, "lo"), expected: "SELECT rpad('hello', 3, 'lo')")
        expectEquivalent(Fn.rTrim("hello", "he"), Fn.rtrim("hello", "he"), expected: "SELECT rtrim('hello', 'he')")
        expectEquivalent(Fn.strPos("hello", "ll"), Fn.strpos("hello", "ll"), expected: "SELECT strpos('hello', 'll')")
        expectEquivalent(Fn.isFinite("4 hours" => .interval), Fn.isfinite("4 hours" => .interval), expected: "SELECT isfinite('4 hours'::interval)")
        expectEquivalent(Fn.localTime, Fn.localtime, expected: "SELECT localtime")
        expectEquivalent(Fn.localTimestamp, Fn.localtimestamp, expected: "SELECT localtimestamp")
        expectEquivalent(Fn.timeOfDay(), Fn.timeofday(), expected: "SELECT timeofday()")
        expectEquivalent(Fn.nTile(4), Fn.ntile(4), expected: "SELECT ntile(4)")
    }

    @Test("Every retained legacy Fn.Name bridge preserves exact SQL identity")
    func legacyFnNameBridges() {
        let bridges: [(legacy: Fn.Name, canonical: Fn.Name, sql: String)] = [
            (.substr, .subStr, "substr"),
            (.setseed, .setSeed, "setseed"),
            (.btrim, .bTrim, "btrim"),
            (.initcap, .initCap, "initcap"),
            (.lpad, .lPad, "lpad"),
            (.ltrim, .lTrim, "ltrim"),
            (.rpad, .rPad, "rpad"),
            (.rtrim, .rTrim, "rtrim"),
            (.strpos, .strPos, "strpos"),
            (.isfinite, .isFinite, "isfinite"),
            (.localtime, .localTime, "localtime"),
            (.localtimestamp, .localTimestamp, "localtimestamp"),
            (.timeofday, .timeOfDay, "timeofday"),
            (.ntile, .nTile, "ntile"),
            (.ifnull, .ifNull, "ifnull"),
            (.isnull, .isNull, "isnull")
        ]

        for bridge in bridges {
            #expect(bridge.legacy.name == bridge.sql)
            #expect(bridge.canonical.name == bridge.sql)
            #expect(bridge.legacy.name == bridge.canonical.name)
        }
    }

    @Test("Final Fn.Name spellings and sequence helpers")
    func finalNames() {
        let names: [(Fn.Name, String)] = [
            (.subStr, "substr"), (.nextVal, "nextval"), (.currVal, "currval"),
            (.ifNull, "ifnull"), (.isNull, "isnull"), (.setSeed, "setseed"),
            (.bTrim, "btrim"), (.initCap, "initcap"), (.concatWS, "concat_ws"),
            (.lPad, "lpad"), (.lTrim, "ltrim"), (.rPad, "rpad"), (.rTrim, "rtrim"),
            (.strPos, "strpos"), (.regExpReplace, "regexp_replace"),
            (.fromUnixTime, "FROM_UNIXTIME"), (.isFinite, "isfinite"),
            (.localTime, "localtime"), (.localTimestamp, "localtimestamp"),
            (.timeOfDay, "timeofday"), (.makeTimestampTZ, "make_timestamptz"),
            (.toTSVector, "to_tsvector"), (.toTSQuery, "to_tsquery"),
            (.plainToTSQuery, "plainto_tsquery"), (.tsRankCD, "ts_rank_cd"),
            (.fromJSON, "from_json"), (.fromJSONStrict, "from_json_strict"),
            (.toJSON, "to_json"), (.arrayToJSON, "array_to_json"), (.rowToJSON, "row_to_json"),
            (.jsonTypeOf, "json_typeof"), (.jsonPopulateRecordSet, "json_populate_recordset"),
            (.jsonToRecordSet, "json_to_recordset"), (.toJSONB, "to_jsonb"),
            (.jsonbTypeOf, "jsonb_typeof"), (.jsonbPopulateRecordSet, "jsonb_populate_recordset"),
            (.jsonbToRecordSet, "jsonb_to_recordset"), (.nTile, "ntile")
        ]
        for (name, expected) in names {
            #expect(name.name == expected)
        }
        #expect(Fn.Name.ifnull.name == Fn.Name.ifNull.name)
        #expect(Fn.Name.isnull.name == Fn.Name.isNull.name)
        #expect(
            SwifQL.select(Fn.nextVal("seq"), Fn.currVal("seq")).prepare(.psql).plain
                == "SELECT nextval('seq'), currval('seq')"
        )
        #expect(SwifQL.select(Fn.ifNull("value", "fallback")).prepare(.psql).plain == "SELECT ifnull('value', 'fallback')")
        #expect(SwifQL.select(Fn.isNull("value", "fallback")).prepare(.psql).plain == "SELECT isnull('value', 'fallback')")
    }

    @Test("Historical snake aliases retarget across SQL families")
    func snakeCaseAliases() {
        let values: [SwifQLable] = ["|", "alpha", 7]
        expectEquivalent(Fn.concatWS(values), Fn.concat_ws(values), expected: "SELECT concat_ws('|', 'alpha', 7)")
        expectEquivalent(Fn.concatWS("|", "alpha", 7), Fn.concat_ws("|", "alpha", 7), expected: "SELECT concat_ws('|', 'alpha', 7)")
        expectEquivalent(Fn.regExpReplace("abc123", "[0-9]+", "#"), Fn.regexp_replace("abc123", "[0-9]+", "#"), expected: "SELECT regexp_replace('abc123', '[0-9]+', '#')")
        expectEquivalent(Fn.fromUnixTime(123, "%Y"), Fn.from_unixtime(123, "%Y"), expected: "SELECT FROM_UNIXTIME(123, '%Y')", dialect: .mysql)
        expectEquivalent(Fn.toTSVector("english", "fat cat"), Fn.to_tsvector("english", "fat cat"), expected: "SELECT to_tsvector('english', 'fat cat')")
        expectEquivalent(Fn.toTSVector("english"), Fn.to_tsvector("english"), expected: "SELECT to_tsvector('english')")
        expectEquivalent(Fn.toTSQuery("english"), Fn.to_tsquery("english"), expected: "SELECT to_tsquery('english')")
        expectEquivalent(Fn.toTSQuery("english", "The & Fat & Rats"), Fn.to_tsquery("english", "The & Fat & Rats"), expected: "SELECT to_tsquery('english', 'The & Fat & Rats')")
        expectEquivalent(Fn.plainToTSQuery("english", "fat cat"), Fn.plainto_tsquery("english", "fat cat"), expected: "SELECT plainto_tsquery('english', 'fat cat')")
        expectEquivalent(Fn.plainToTSQuery("english"), Fn.plainto_tsquery("english"), expected: "SELECT plainto_tsquery('english')")
        expectEquivalent(Fn.tsRankCD("vector", Fn.toTSQuery("fat")), Fn.ts_rank_cd("vector", Fn.to_tsquery("fat")), expected: "SELECT ts_rank_cd('vector', to_tsquery('fat'))")
        expectEquivalent(Fn.makeTimestampTZ(2013, 7, 15, 8, 15, 23.5), Fn.make_timestamptz(2013, 7, 15, 8, 15, 23.5), expected: "SELECT make_timestamptz(2013, 7, 15, 8, 15, 23.5)")
        expectEquivalent(Fn.makeTimestampTZ(2013, 7, 15, 8, 15, 23.5, "UTC"), Fn.make_timestamptz(2013, 7, 15, 8, 15, 23.5, "UTC"), expected: "SELECT make_timestamptz(2013, 7, 15, 8, 15, 23.5, 'UTC')")
    }

    @Test("Final Duck and PostgreSQL JSON names preserve labels and binds")
    func jsonNamesAndLabels() {
        let json = #"{"a":1}"#
        let structure = #"{"a":"INTEGER"}"#
        expectEquivalent(Fn.toJSON(json), Fn.to_json(json), expected: #"SELECT to_json('{"a":1}')"#)
        expectEquivalent(Fn.arrayToJSON(json), Fn.array_to_json(json), expected: #"SELECT array_to_json('{"a":1}')"#)
        expectEquivalent(Fn.arrayToJSON(json, pretty: true), Fn.array_to_json(json, pretty: true), expected: #"SELECT array_to_json('{"a":1}', TRUE)"#)
        expectEquivalent(Fn.rowToJSON(json), Fn.row_to_json(json), expected: #"SELECT row_to_json('{"a":1}')"#)
        expectEquivalent(Fn.rowToJSON(json, pretty: true), Fn.row_to_json(json, pretty: true), expected: #"SELECT row_to_json('{"a":1}', TRUE)"#)
        expectEquivalent(Fn.jsonTypeOf(json), Fn.json_typeof(json), expected: #"SELECT json_typeof('{"a":1}')"#)
        expectEquivalent(Fn.jsonPopulateRecord(base: "base", fromJSON: json), Fn.json_populate_record(base: "base", from_json: json), expected: #"SELECT json_populate_record('base', '{"a":1}')"#)
        expectEquivalent(Fn.jsonPopulateRecordSet(base: "base", fromJSON: json), Fn.json_populate_recordset(base: "base", from_json: json), expected: #"SELECT json_populate_recordset('base', '{"a":1}')"#)
        expectEquivalent(Fn.jsonToRecordSet(json), Fn.json_to_recordset(json), expected: #"SELECT json_to_recordset('{"a":1}')"#)
        expectEquivalent(Fn.toJSONB(json), Fn.to_jsonb(json), expected: #"SELECT to_jsonb('{"a":1}')"#)
        expectEquivalent(Fn.jsonbTypeOf(json), Fn.jsonb_typeof(json), expected: #"SELECT jsonb_typeof('{"a":1}')"#)
        expectEquivalent(Fn.jsonbPopulateRecord(base: "base", fromJSON: json), Fn.jsonb_populate_record(base: "base", from_json: json), expected: #"SELECT jsonb_populate_record('base', '{"a":1}')"#)
        expectEquivalent(Fn.jsonbPopulateRecordSet(base: "base", fromJSON: json), Fn.jsonb_populate_recordset(base: "base", from_json: json), expected: #"SELECT jsonb_populate_recordset('base', '{"a":1}')"#)
        expectEquivalent(Fn.jsonbToRecordSet(json), Fn.jsonb_to_recordset(json), expected: #"SELECT jsonb_to_recordset('{"a":1}')"#)
        let prepared = SwifQL.select(Fn.fromJSON(json, structure: structure), Fn.fromJSONStrict(json, structure: structure)).prepare(.duck)
        #expect(prepared.plain == #"SELECT from_json('{"a":1}', '{"a":"INTEGER"}'), from_json_strict('{"a":1}', '{"a":"INTEGER"}')"#)
        #expect(prepared.splitted.query == "SELECT from_json($1, $2), from_json_strict($3, $4)")
        #expect(prepared.splitted.values.map { $0 as? String } == [json, structure, json, structure])
    }

    @Test("Preserved SQL-shaped names remain available")
    func preservedNames() {
        #expect(Fn.Name.readCSV.name == "read_csv")
        #expect(Fn.Name.readJSON.name == "read_json")
        #expect(Fn.Name.readParquet.name == "read_parquet")
        #expect(SwifQL.from(Fn.readCSV("events.csv")).prepare(.duck).plain == "FROM read_csv('events.csv')")
        #expect(SwifQL.from(Fn.readJSON("events.json")).prepare(.duck).plain == "FROM read_json('events.json')")
        #expect(SwifQL.select(Fn.fromBase64("SGVsbG8="), Fn.groupingId("region")).prepare(.duck).plain == "SELECT from_base64('SGVsbG8='), grouping_id('region')")
        #expect(SwifQL.select(Fn.jsonExtractPath("{}", pathElems: ["a", "b"])).prepare(.psql).plain == "SELECT json_extract_path('{}', 'a', 'b')")
        #expect(SwifQL.select(Fn.makeInterval(mins: 2, secs: 3)).prepare(.psql).plain == "SELECT make_interval(mins => 2, secs => 3)")
    }
}
