@testable import SQL
import Foundation
import Testing

@Suite("Duck Type Tests")
struct DuckTypeTests: SwifQLTests {
    @Test("Native Duck scalar types render their exact names")
    func scalarTypes() {
        let types: [(Type, String)] = [
            (.tinyint, "tinyint"),
            (.hugeint, "hugeint"),
            (.utinyint, "utinyint"),
            (.usmallint, "usmallint"),
            (.uinteger, "uinteger"),
            (.ubigint, "ubigint"),
            (.uhugeint, "uhugeint"),
            (.blob, "blob"),
            (.timestampS, "timestamp_s"),
            (.timestampMs, "timestamp_ms"),
            (.timestampNs, "timestamp_ns"),
            (.timeNs, "time_ns"),
            (.variant, "variant")
        ]

        for (type, name) in types {
            #expect(type.name == name)
        }
    }

    @Test("LIST and fixed ARRAY retain distinct SQL shapes")
    func listAndArray() {
        let list = Type.list(.integer)
        let array = Type.array(.integer, length: 3)

        #expect(list.name == "integer[]")
        #expect(array.name == "integer[3]")
        #expect(list.name != array.name)
        #expect(SwifQL.select("value" => list).prepare(.duck).plain == "SELECT 'value'::integer[]")
        #expect(SwifQL.select("value" => array).prepare(.duck).plain == "SELECT 'value'::integer[3]")
    }

    @Test("Nested Type values retain semantic constructor structure")
    func structuredRepresentation() {
        let list = Type.list(.integer)
        let array = Type.array(list, length: 3)
        let map = Type.map(key: .varchar, value: array)
        let structure = Type.`struct`(("select", .integer), ("items", list))
        let union = Type.union(("payload", map))

        #expect(Type("custom").structuredRepresentation == nil)
        #expect(list.structuredRepresentation == .collection(.list, element: .integer, length: nil))
        #expect(array.structuredRepresentation == .collection(.array, element: list, length: 3))
        #expect(
            map.structuredRepresentation ==
                .map(.map, key: .varchar, value: array)
        )
        #expect(
            structure.structuredRepresentation ==
                .members(
                    .struct,
                    [
                        TypeMember("select", .integer),
                        TypeMember("items", list)
                    ]
                )
        )
        #expect(
            union.structuredRepresentation ==
                .members(.union, [TypeMember("payload", map)])
        )
    }

    @Test("MAP STRUCT UNION and VARIANT compose recursively")
    func nestedTypes() {
        let map = Type.map(key: .varchar, value: .integer)
        let structure = Type.`struct`(("name", .varchar), ("age", .integer))
        let union = Type.union(("number", .integer), ("string", .varchar))
        let listOfStruct = Type.list(structure)
        let mapOfStruct = Type.map(key: .varchar, value: structure)

        #expect(map.name == "MAP(varchar, integer)")
        #expect(structure.name == "STRUCT(\"name\" varchar, \"age\" integer)")
        #expect(union.name == "UNION(\"number\" integer, \"string\" varchar)")
        #expect(listOfStruct.name == "STRUCT(\"name\" varchar, \"age\" integer)[]")
        #expect(mapOfStruct.name == "MAP(varchar, STRUCT(\"name\" varchar, \"age\" integer))")
        #expect(Type.variant.name == "variant")
    }

    @Test("Nested member identifiers use SQL identifier escaping")
    func nestedMemberIdentifiers() {
        let structure = Type.`struct`(
            ("name", .integer),
            ("select", .integer),
            ("名前", .integer),
            ("a\"b", .integer)
        )
        let union = Type.union(("a\"b", .integer))

        #expect(structure.name == "STRUCT(\"name\" integer, \"select\" integer, \"名前\" integer, \"a\"\"b\" integer)")
        #expect(union.name == "UNION(\"a\"\"b\" integer)")

        let globalPath = Path.Schema("analytics").table("events").column("payload")
        #expect(globalPath.prepare(.duck).plain == "\"analytics\".\"events\".\"payload\"")
    }

    @Test("Nested Type values compose through casts and column consumers")
    func typeConsumers() {
        let nested = Type.map(key: .varchar, value: Type.list(.integer))
        let cast = Fn.cast("payload", nested)
        let column = NewColumn("payload", nested)

        #expect(cast.prepare(.duck).plain == "cast('payload' as MAP(varchar, integer[]))")
        #expect(column.prepare(.duck).plain == "\"payload\" MAP(varchar, integer[])")
    }

    @Test("Stored Type values preserve exact output")
    func storedTypes() {
        let stored: Type = Type.`struct`([("name", .varchar), ("age", .integer)])
        let copied = stored

        #expect(stored.name == copied.name)
        #expect(Fn.cast("payload", stored).prepare(.duck).plain == Fn.cast("payload", copied).prepare(.duck).plain)
    }

    @Test("Historical Type inference and PostgreSQL-only names remain unchanged")
    func historicalBoundaries() {
        #expect(Type.auto(from: Int.self, isPrimary: false).name == "int")
        #expect(Type.auto(from: Int.self, isPrimary: true).name == "serial")
        #expect(Type.auto(from: Int64.self, isPrimary: false).name == "bigint")
        #expect(Type.auto(from: Int64.self, isPrimary: true).name == "bigserial")
        #expect(Type.jsonb.name == "jsonb")
        #expect(Type.int4range.name == "int4range")
        #expect(Type.oid.name == "oid")
        #expect(Type.serial.name == "serial")
        #expect(Type.timestamp(3).name == "timestamp(3) with time zone")
        #expect(Type.time(3).name == "time(3) with time zone")
    }

    @Test("Type definitions do not add named values or inference routing")
    func typeOnlySurface() {
        let query = SwifQL.select(Fn.cast("payload", Type.`struct`(("name", .varchar))))
        let sql = query.prepare(.duck).plain

        #expect(sql == "SELECT cast('payload' as STRUCT(\"name\" varchar))")
        #expect(!sql.contains(":="))
        #expect(!sql.contains("sequence"))
        #expect(!sql.contains("serial"))
    }
}
