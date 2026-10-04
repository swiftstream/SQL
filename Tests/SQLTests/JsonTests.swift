@testable import SQL
import Testing

@Suite("Json Tests")
struct JsonTests: SwifQLTests {
    // MARK: - JSON
    
    @Test("Test Json Extract Path")
    func jsonExtractPath() {
        let json = #"{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}"#
        check(
            SwifQL.select(Fn.jsonExtractPath(json, pathElems: ["f4"])),
            .psql(#"SELECT json_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4')"#),
            .mysql(#"SELECT json_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4')"#),
            .duck(#"SELECT json_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4')"#)
        )
    }
    
    @Test("Test Json Extract Path Text")
    func jsonExtractPathText() {
        let json = #"{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}"#
        check(
            SwifQL.select(Fn.jsonExtractPathText(json, pathElems: ["f4", "f6"])),
            .psql(#"SELECT json_extract_path_text('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4', 'f6')"#),
            .mysql(#"SELECT json_extract_path_text('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4', 'f6')"#)
        )
    }

    @Test("Existing JSON path SQL remains exact for PostgreSQL and MySQL")
    func legacyKeyPathDialectOutput() {
        check(
            Path.Table("events").column("payload", "field"),
            .psql(#""events"."payload"->'field'"#),
            .mysql("events.field")
        )
    }
    
    @Test("Test Jsonb Extract Path")
    func jsonbExtractPath() {
        let json = #"{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}"#
        check(
            SwifQL.select(Fn.jsonbExtractPath(json, pathElems: ["f4"])),
            .psql(#"SELECT jsonb_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4')"#),
            .mysql(#"SELECT jsonb_extract_path('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4')"#)
        )
    }
    
    @Test("Test Jsonb Extract Path Text")
    func jsonbExtractPathText() {
        let json = #"{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}"#
        check(
            SwifQL.select(Fn.jsonbExtractPathText(json, pathElems: ["f4", "f6"])),
            .psql(#"SELECT jsonb_extract_path_text('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4', 'f6')"#),
            .mysql(#"SELECT jsonb_extract_path_text('{"f2":{"f3":1},"f4":{"f5":99,"f6":"foo"}}', 'f4', 'f6')"#)
        )
    }
}
