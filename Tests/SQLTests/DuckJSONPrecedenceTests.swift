@testable import SQL
import Testing

@Suite("Duck JSON precedence and exact surface")
struct DuckJSONPrecedenceTests: SwifQLTests {
    private let payload = Path.Table("events").column("payload")
    private let field = Path.Table("events").column("payload", "field")
    private let fieldText = SwifQLPartKeyPath(
        table: "events",
        paths: ["payload", "field"],
        asText: true
    )
    private let nestedText = SwifQLPartKeyPath(
        table: "events",
        paths: ["payload", "nested", "field"],
        asText: true
    )

    @Test("Duck protects only traversed key paths")
    func keyPathProtection() {
        #expect(payload.prepare(.duck).plain == #""events"."payload""#)
        #expect(field.prepare(.duck).plain == #"("events"."payload"->'field')"#)
        #expect(nestedText.prepare(.duck).plain == #"("events"."payload"->'nested'->>'field')"#)
    }

    @Test("Duck traversal protection composes through aliases, functions, ordering, and predicates")
    func grammarPositions() {
        let alias = field => "field_value"
        let length = Fn.subStr(nestedText, 1)
        let order = SwifQL.select(field).from(Path.Table("events")).orderBy(.asc(field))
        let predicate = fieldText == "alpha"

        #expect(SwifQL.select(alias).prepare(.duck).plain == #"SELECT ("events"."payload"->'field') as "field_value""#)
        #expect(SwifQL.select(length).prepare(.duck).plain == #"SELECT substr(("events"."payload"->'nested'->>'field'), 1)"#)
        #expect(order.prepare(.duck).plain == #"SELECT ("events"."payload"->'field') FROM "events" ORDER BY ("events"."payload"->'field') ASC"#)
        #expect(SwifQL.select(field).from(Path.Table("events")).where(predicate).prepare(.duck).plain == #"SELECT ("events"."payload"->'field') FROM "events" WHERE ("events"."payload"->>'field') = 'alpha'"#)
        #expect(predicate.prepare(.psql).plain == #""events"."payload"->>'field' = 'alpha'"#)
        #expect(predicate.prepare(.mysql).plain == "events.field = 'alpha'")
    }

    @Test("Copied and helper-composed traversals retain one protected expression")
    func copiedComposition() {
        let helper: () -> SwifQLable = { self.field }
        let copied = SwifQLableParts(parts: helper().parts)
        let nested = Fn.jsonValue(copied, path: "$")

        #expect(copied.prepare(.duck).plain == field.prepare(.duck).plain)
        #expect(SwifQL.select(nested).prepare(.duck).plain == #"SELECT json_value(("events"."payload"->'field'), '$')"#)
    }

    @Test("Duck JSON index composition stays distinct from LIST indexing")
    func indexes() {
        let jsonSubscript = payload["items"][0]
        let list = SwifQLableParts(parts: [10, 20])

        #expect(SwifQL.select(field).prepare(.duck).plain == #"SELECT ("events"."payload"->'field')"#)
        #expect(SwifQL.select(jsonSubscript).from(Path.Table("events")).prepare(.duck).plain == #"SELECT "events"."payload"['items'][0] FROM "events""#)
        #expect(SwifQL.select(list[1]).prepare(.duck).plain == "SELECT [10,20][1]")
    }

    @Test("Exact Duck JSON helpers use native names and composed arguments")
    func exactFunctions() {
        let json = #"{"a":"alpha","n":7}"#
        let structure = #"{"a":"VARCHAR","n":"INTEGER"}"#

        check(
            SwifQL.select(
                Fn.jsonArray(1, "alpha"),
                Fn.jsonMergePatch(json, #"{"b":2}"#),
                Fn.jsonGroupArray(1),
                Fn.jsonGroupObject("a", 1),
                Fn.jsonGroupStructure(json),
                Fn.jsonKeys(json),
                Fn.jsonKeys(json, path: "a"),
                Fn.jsonStructure(json),
                Fn.jsonType(json),
                Fn.jsonType(json, path: "a"),
                Fn.jsonValid(json),
                Fn.jsonValue(json, path: "$.a"),
                Fn.jsonTransform(json, structure: structure),
                Fn.fromJSON(json, structure: structure),
                Fn.jsonTransformStrict(json, structure: structure),
                Fn.fromJSONStrict(json, structure: structure)
            ),
            .duck(#"SELECT json_array(1, 'alpha'), json_merge_patch('{"a":"alpha","n":7}', '{"b":2}'), json_group_array(1), json_group_object('a', 1), json_group_structure('{"a":"alpha","n":7}'), json_keys('{"a":"alpha","n":7}'), json_keys('{"a":"alpha","n":7}', 'a'), json_structure('{"a":"alpha","n":7}'), json_type('{"a":"alpha","n":7}'), json_type('{"a":"alpha","n":7}', 'a'), json_valid('{"a":"alpha","n":7}'), json_value('{"a":"alpha","n":7}', '$.a'), json_transform('{"a":"alpha","n":7}', '{"a":"VARCHAR","n":"INTEGER"}'), from_json('{"a":"alpha","n":7}', '{"a":"VARCHAR","n":"INTEGER"}'), json_transform_strict('{"a":"alpha","n":7}', '{"a":"VARCHAR","n":"INTEGER"}'), from_json_strict('{"a":"alpha","n":7}', '{"a":"VARCHAR","n":"INTEGER"}')"#)
        )

        let prepared = SwifQL.select(Fn.jsonMergePatch(json, structure)).prepare(.duck)
        #expect(prepared.splitted.query == "SELECT json_merge_patch($1, $2)")
        #expect(prepared.splitted.values.map { $0 as? String } == [json, structure])
    }

    @Test("Exact Duck JSON helpers support the table-function composition")
    func tableFunction() {
        #expect(
            SwifQL.from(Fn.jsonTree(#"{"a":1}"#)).prepare(.duck).plain
                == #"FROM json_tree('{"a":1}')"#
        )
        #expect(
            SwifQL.from(Fn.jsonTree(#"{"a":1}"#, path: "$.a")).prepare(.duck).plain
                == #"FROM json_tree('{"a":1}', '$.a')"#
        )
    }
}
