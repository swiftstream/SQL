import Foundation
import Testing
@testable import SQL

private struct SQLJSONDocument: Table {
    static var tableName: String { "documents" }

    @Column("payload") var payload: String
    @Column("score") var score: Int

    init() {}
}

private final class SQLJSONPartsProbe: SQLable {
    private let snapshot: [SQLPart]
    private(set) var evaluations = 0

    init(_ snapshot: [SQLPart]) {
        self.snapshot = snapshot
    }

    var parts: [SQLPart] {
        evaluations += 1
        return snapshot
    }
}

/// A downstream dialect that does not opt into any contextual policy. It still
/// observes the grammar role through the shared context-aware hook.
private final class SQLJSONCustomDialect: SQLDialect {
    private(set) var seenRoles: [String] = []

    override var id: String? { "custom-sql-json-probe" }

    override func inlineUnsafeValue(
        _ value: Encodable,
        context: SQLRenderContext
    ) -> String? {
        if let scope = SQLJSONRenderScope.resolve(context.currentScope) {
            let role = scope.role == .path ? "path" : "directRuntimeDefault"
            seenRoles.append("\(role):\(scope.owner.name)")
        }
        return nil
    }
}

private func completeOccurrences(
    of observed: SQLObservedPrepared
) -> [SQLUnsafeValueOccurrence] {
    switch observed.unsafeValueTrace {
    case .complete(let occurrences):
        return occurrences
    case .unavailable:
        Issue.record("Expected a complete unsafe-value trace")
        return []
    }
}

@Suite("Expression Frontier 02 Wave B SQL/JSON")
struct ExpressionFrontierSQLJSONTests: SwifQLTests {
    private typealias Fixture = SQLJSONDocument

    // MARK: - Owners

    @Test("SQL/JSON owners render their exact SQL identity")
    func ownerIdentities() {
        check(
            JSONExists(Fixture.$payload, "$.name"),
            .psql(
                "JSON_EXISTS(\"documents\".\"payload\", '$.name')",
                "JSON_EXISTS(\"documents\".\"payload\", $1)"
            ),
            .mysql(
                "JSON_EXISTS(documents.payload, '$.name')",
                "JSON_EXISTS(documents.payload, ?)"
            ),
            .duck(
                "JSON_EXISTS(\"documents\".\"payload\", '$.name')",
                "JSON_EXISTS(\"documents\".\"payload\", $1)"
            )
        )

        check(
            JSONValue(Fixture.$payload, "$.name"),
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.name')",
                "JSON_VALUE(\"documents\".\"payload\", $1)"
            ),
            .mysql(
                "JSON_VALUE(documents.payload, '$.name')",
                "JSON_VALUE(documents.payload, ?)"
            ),
            .duck(
                "JSON_VALUE(\"documents\".\"payload\", '$.name')",
                "JSON_VALUE(\"documents\".\"payload\", $1)"
            )
        )

        check(
            JSONQuery(Fixture.$payload, "$.name"),
            .psql(
                "JSON_QUERY(\"documents\".\"payload\", '$.name')",
                "JSON_QUERY(\"documents\".\"payload\", $1)"
            ),
            .mysql(
                "JSON_QUERY(documents.payload, '$.name')",
                "JSON_QUERY(documents.payload, ?)"
            )
        )

        // No substitute identity: the three owners keep their own function names.
        #expect(
            JSONExists(Fixture.$payload, "$.p").prepare(.psql).plain
                != JSONValue(Fixture.$payload, "$.p").prepare(.psql).plain
        )
    }

    @Test("Owners snapshot document and path exactly once")
    func singleSnapshotArguments() {
        let document = SQLJSONPartsProbe([SQLPartColumn("payload")])
        let path = SQLJSONPartsProbe([SQLPartUnsafeValue("$.name")])

        let expression = JSONValue(document, path)
        #expect(document.evaluations == 1)
        #expect(path.evaluations == 1)

        #expect(expression.prepare(.mysql).splitted.query == "JSON_VALUE(payload, ?)")
        #expect(document.evaluations == 1)
        #expect(path.evaluations == 1)
    }

    // MARK: - Paths

    @Test("Direct runtime String path stays bound in every built-in dialect")
    func runtimePathRemainsBound() {
        let expression = JSONValue(Fixture.$payload, "$.name")

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let prepared = expression.prepare(dialect)
            let values = prepared.splitted.values
            #expect(values.count == 1)
            #expect(values[0] as? String == "$.name")

            let occurrences = completeOccurrences(
                of: expression.prepareObservingUnsafeValues(dialect)
            )
            #expect(occurrences.count == 1)
            #expect(occurrences[0].disposition == .bound(index: 0))
            #expect(occurrences[0].disposition != .notBound)
        }
    }

    @Test("MySQL runtime path payload never enters generated SQL structure")
    func mysqlPathNeverEntersSQLStructure() {
        let payloads = [
            "$.name",
            "$.\"a'b\"",
            "$.\"a\\b\"",
            "$.\"a'b\\c\"",
            "x' OR '1'='1",
            "$.\"é'ß\\中\"",
        ]

        for payload in payloads {
            let expression = JSONValue(Fixture.$payload, payload)
            let splitted = expression.prepare(.mysql).splitted

            #expect(splitted.query == "JSON_VALUE(documents.payload, ?)")
            #expect(!splitted.query.contains(payload))
            #expect(!splitted.query.contains("_utf8mb4"))
            #expect(!splitted.query.contains("X'"))
            #expect(!splitted.query.contains("'"))
            #expect(splitted.values.count == 1)
            #expect(splitted.values[0] as? String == payload)

            let occurrences = completeOccurrences(
                of: expression.prepareObservingUnsafeValues(.mysql)
            )
            #expect(occurrences.map(\.disposition) == [.bound(index: 0)])
        }
    }

    @Test("MySQL fixed structural path is caller-owned SQL and binds nothing")
    func mysqlFixedStructuralPath() {
        let expression = JSONValue(Fixture.$payload, SQL.raw("'$.name'"))

        check(
            expression,
            .psql("JSON_VALUE(\"documents\".\"payload\", '$.name')"),
            .mysql("JSON_VALUE(documents.payload, '$.name')"),
            .duck("JSON_VALUE(\"documents\".\"payload\", '$.name')")
        )
        #expect(expression.prepare(.mysql).splitted.values.isEmpty)
        #expect(
            completeOccurrences(of: expression.prepareObservingUnsafeValues(.mysql)).isEmpty
        )
    }

    @Test("MySQL keeps neighbouring binds ordered around a bound path")
    func mysqlNeighbouringBindOrder() {
        let expression = JSONValue(Fixture.$payload, "$.p") {
            DefaultOnEmpty(Fn.coalesce(1, 2))
            ErrorOnError()
        }

        check(
            expression,
            .mysql(
                "JSON_VALUE(documents.payload, '$.p' DEFAULT coalesce(1,2) ON EMPTY ERROR ON ERROR)",
                "JSON_VALUE(documents.payload, ? DEFAULT coalesce(?,?) ON EMPTY ERROR ON ERROR)"
            ),
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' DEFAULT coalesce(1,2) ON EMPTY ERROR ON ERROR)",
                "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT coalesce($2,$3) ON EMPTY ERROR ON ERROR)"
            )
        )

        let values = expression.prepare(.mysql).splitted.values
        #expect(values.count == 3)
        #expect(values[0] as? String == "$.p")
        #expect(values[1] as? Int == 1)
        #expect(values[2] as? Int == 2)

        let occurrences = completeOccurrences(
            of: expression.prepareObservingUnsafeValues(.mysql)
        )
        #expect(occurrences.map(\.disposition) == [
            .bound(index: 0),
            .bound(index: 1),
            .bound(index: 2),
        ])
    }

    // MARK: - PASSING

    @Test("PASSING entries coalesce under one keyword in source order")
    func passingCoalescing() {
        check(
            JSONValue(Fixture.$payload, "$.p") {
                Passing(2, as: "lim")
            },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 2 AS \"lim\")",
                "JSON_VALUE(\"documents\".\"payload\", $1 PASSING $2 AS \"lim\")"
            )
        )

        check(
            JSONValue(Fixture.$payload, "$.p") {
                Passing(2, as: "lim")
                Passing(3, as: "off")
            },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 2 AS \"lim\", 3 AS \"off\")",
                "JSON_VALUE(\"documents\".\"payload\", $1 PASSING $2 AS \"lim\", $3 AS \"off\")"
            )
        )

        let names = ["lim", "off"]
        check(
            JSONValue(Fixture.$payload, "$.p") {
                for name in names {
                    Passing(1, as: name)
                }
            },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 1 AS \"lim\", 1 AS \"off\")",
                "JSON_VALUE(\"documents\".\"payload\", $1 PASSING $2 AS \"lim\", $3 AS \"off\")"
            )
        )
    }

    @Test("PASSING name is structural identifier identity")
    func passingIdentifier() {
        check(
            JSONValue(Fixture.$payload, "$.p") {
                Passing(1, as: "a\"b")
            },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 1 AS \"a\"\"b\")",
                "JSON_VALUE(\"documents\".\"payload\", $1 PASSING $2 AS \"a\"\"b\")"
            )
        )

        // The identifier never becomes a bound value.
        let values = JSONValue(Fixture.$payload, "$.p") {
            Passing(1, as: "lim")
        }.prepare(.psql).splitted.values
        #expect(values.count == 2)
        #expect(values[0] as? String == "$.p")
        #expect(values[1] as? Int == 1)
    }

    @Test("PASSING presence follows runtime control flow")
    func passingControlFlow() {
        let include = true
        let omitted = false

        check(
            JSONValue(Fixture.$payload, "$.p") {
                if include {
                    Passing(2, as: "lim")
                }
                Returning(.text)
            },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 2 AS \"lim\" RETURNING TEXT)"
            )
        )

        check(
            JSONValue(Fixture.$payload, "$.p") {
                if omitted {
                    Passing(2, as: "lim")
                }
                Returning(.text)
            },
            .psql("JSON_VALUE(\"documents\".\"payload\", '$.p' RETURNING TEXT)")
        )

        let preferLimit = true
        check(
            JSONValue(Fixture.$payload, "$.p") {
                if preferLimit {
                    Passing(7, as: "chosen")
                } else {
                    Passing(8, as: "chosen")
                }
            },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 7 AS \"chosen\")"
            )
        )
    }

    // MARK: - RETURNING

    @Test("RETURNING tokens keep dialect-owned grammar")
    func returningTokens() {
        check(
            JSONValue(Fixture.$payload, "$.p") { Returning(.integer) },
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' RETURNING INTEGER)",
                "JSON_VALUE(\"documents\".\"payload\", $1 RETURNING INTEGER)"
            ),
            .mysql(
                "JSON_VALUE(documents.payload, '$.p' RETURNING SIGNED)",
                "JSON_VALUE(documents.payload, ? RETURNING SIGNED)"
            )
        )

        check(
            JSONValue(Fixture.$payload, "$.p") { Returning(.jsonb) },
            .psql("JSON_VALUE(\"documents\".\"payload\", '$.p' RETURNING JSONB)")
        )

        check(
            JSONValue(Fixture.$payload, "$.p") { Returning(.text) },
            .psql("JSON_VALUE(\"documents\".\"payload\", '$.p' RETURNING TEXT)")
        )

        check(
            JSONQuery(Fixture.$payload, "$.p") {
                Returning(.text, format: .json)
            },
            .psql("JSON_QUERY(\"documents\".\"payload\", '$.p' RETURNING TEXT FORMAT JSON)")
        )

        // No portability mapping of the remaining vocabulary types: MySQL keeps
        // the authored `JSONB` token instead of substituting its own `JSON`.
        #expect(
            JSONValue(Fixture.$payload, "$.p") { Returning(.jsonb) }
                .prepare(.mysql).plain
                == "JSON_VALUE(documents.payload, '$.p' RETURNING JSONB)"
        )
        #expect(
            JSONValue(Fixture.$payload, "$.p") { Returning(.text) }
                .prepare(.mysql).plain
                == "JSON_VALUE(documents.payload, '$.p' RETURNING TEXT)"
        )
    }

    // MARK: - DEFAULT

    @Test("PostgreSQL direct runtime DEFAULT becomes a parser constant")
    func postgresDirectDefault() {
        let integer = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty(0) }
        check(
            integer,
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' DEFAULT 0 ON EMPTY)",
                "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT 0 ON EMPTY)"
            )
        )
        #expect(integer.prepare(.psql).splitted.values.count == 1)
        #expect(
            completeOccurrences(of: integer.prepareObservingUnsafeValues(.psql))
                .map(\.disposition) == [.bound(index: 0), .notBound]
        )

        let text = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty("fallback") }
        check(
            text,
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' DEFAULT E'fallback' ON EMPTY)",
                "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT E'fallback' ON EMPTY)"
            )
        )
        #expect(text.prepare(.psql).splitted.values.count == 1)
        #expect(
            completeOccurrences(of: text.prepareObservingUnsafeValues(.psql))
                .map(\.disposition) == [.bound(index: 0), .notBound]
        )
    }

    @Test("PostgreSQL DEFAULT escaping keeps one literal payload")
    func postgresDefaultEscaping() {
        let cases: [(payload: String, expected: String)] = [
            ("a'b", "E'a''b'"),
            ("a\\b", "E'a\\\\b'"),
            ("a'b\\c", "E'a''b\\\\c'"),
            ("'lead", "E'''lead'"),
            ("trail'", "E'trail'''"),
            ("x' OR '1'='1", "E'x'' OR ''1''=''1'"),
            ("é'ß", "E'é''ß'"),
        ]

        for (payload, expected) in cases {
            let expression = JSONValue(Fixture.$payload, "$.p") {
                DefaultOnEmpty(payload)
            }
            let splitted = expression.prepare(.psql).splitted
            #expect(
                splitted.query
                    == "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT \(expected) ON EMPTY)"
            )
            #expect(splitted.values.count == 1)
            #expect(splitted.values[0] as? String == "$.p")
            #expect(
                completeOccurrences(of: expression.prepareObservingUnsafeValues(.psql))
                    .map(\.disposition) == [.bound(index: 0), .notBound]
            )
        }
    }

    @Test("MySQL JSON_VALUE direct String DEFAULT uses introduced uppercase hex")
    func mysqlDirectDefault() {
        let integer = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty(0) }
        check(
            integer,
            .mysql(
                "JSON_VALUE(documents.payload, '$.p' DEFAULT 0 ON EMPTY)",
                "JSON_VALUE(documents.payload, ? DEFAULT 0 ON EMPTY)"
            )
        )
        #expect(integer.prepare(.mysql).splitted.values.count == 1)
        #expect(
            completeOccurrences(of: integer.prepareObservingUnsafeValues(.mysql))
                .map(\.disposition) == [.bound(index: 0), .notBound]
        )

        let text = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty("fallback") }
        check(
            text,
            .mysql(
                "JSON_VALUE(documents.payload, '$.p' DEFAULT _utf8mb4 X'66616C6C6261636B' ON EMPTY)",
                "JSON_VALUE(documents.payload, ? DEFAULT _utf8mb4 X'66616C6C6261636B' ON EMPTY)"
            )
        )

        let cases: [(payload: String, hex: String)] = [
            ("a'b", "612762"),
            ("a\\b", "615C62"),
            ("a'b\\c", "6127625C63"),
            ("x' OR '1'='1", "7827204F52202731273D2731"),
            ("é'ß", "C3A927C39F"),
        ]

        for (payload, hex) in cases {
            let expression = JSONValue(Fixture.$payload, "$.p") {
                DefaultOnEmpty(payload)
            }
            let splitted = expression.prepare(.mysql).splitted
            #expect(
                splitted.query
                    == "JSON_VALUE(documents.payload, ? DEFAULT _utf8mb4 X'\(hex)' ON EMPTY)"
            )
            #expect(!splitted.query.contains(payload))
            // Only hexadecimal digits are emitted from the payload bytes.
            let token = splitted.query.components(separatedBy: "X'")[1]
                .components(separatedBy: "'")[0]
            #expect(token.allSatisfy { character in character.isHexDigit })
            #expect(token == token.uppercased())
            #expect(splitted.values.count == 1)
            #expect(splitted.values[0] as? String == "$.p")
            #expect(
                completeOccurrences(of: expression.prepareObservingUnsafeValues(.mysql))
                    .map(\.disposition) == [.bound(index: 0), .notBound]
            )
        }
    }

    @Test("MySQL introduced hex stays inside the JSON_VALUE DEFAULT role")
    func mysqlDefaultRoleIsOwnerSpecific() {
        // MySQL owns no JSON_QUERY identity, and the hex policy is proven only
        // for the JSON_VALUE DEFAULT role, so this value keeps ordinary binding.
        let query = JSONQuery(Fixture.$payload, "$.p") { DefaultOnEmpty("x") }
        let splitted = query.prepare(.mysql).splitted
        #expect(splitted.query == "JSON_QUERY(documents.payload, ? DEFAULT ? ON EMPTY)")
        #expect(splitted.values.count == 2)
        #expect(splitted.values[1] as? String == "x")
        #expect(
            completeOccurrences(of: query.prepareObservingUnsafeValues(.mysql))
                .map(\.disposition) == [.bound(index: 0), .bound(index: 1)]
        )

        // The hex form is never emitted in the path position.
        let path = JSONValue(Fixture.$payload, "$.p") { Returning(.integer) }
        #expect(!path.prepare(.mysql).splitted.query.contains("_utf8mb4"))
    }

    @Test("Structural DEFAULT keeps nested bound children")
    func structuralDefaultStaysStructural() {
        let expression = JSONValue(Fixture.$payload, "$.p") {
            DefaultOnEmpty(Fn.coalesce(Fixture.$score, "fallback"))
            ErrorOnError()
        }

        check(
            expression,
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' DEFAULT coalesce(\"documents\".\"score\",'fallback') ON EMPTY ERROR ON ERROR)",
                "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT coalesce(\"documents\".\"score\",$2) ON EMPTY ERROR ON ERROR)"
            )
        )

        let values = expression.prepare(.psql).splitted.values
        #expect(values.count == 2)
        #expect(values[0] as? String == "$.p")
        #expect(values[1] as? String == "fallback")

        let occurrences = completeOccurrences(
            of: expression.prepareObservingUnsafeValues(.psql)
        )
        #expect(occurrences.map(\.disposition) == [.bound(index: 0), .bound(index: 1)])
    }

    @Test("Unsupported direct DEFAULT category remains bound and fails closed")
    func unsupportedDirectDefaultCategory() {
        let expression = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty(1.5) }

        check(
            expression,
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' DEFAULT 1.5 ON EMPTY)",
                "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT $2 ON EMPTY)"
            ),
            .mysql(
                "JSON_VALUE(documents.payload, '$.p' DEFAULT 1.5 ON EMPTY)",
                "JSON_VALUE(documents.payload, ? DEFAULT ? ON EMPTY)"
            )
        )

        for dialect in [SQLDialect.psql, .mysql] {
            let values = expression.prepare(dialect).splitted.values
            #expect(values.count == 2)
            #expect(values[1] as? Double == 1.5)
            #expect(
                completeOccurrences(of: expression.prepareObservingUnsafeValues(dialect))
                    .map(\.disposition) == [.bound(index: 0), .bound(index: 1)]
            )
        }
    }

    // MARK: - Observation and regression

    @Test("Contextual consumption is observed only for the consumed occurrence")
    func contextualObservation() {
        let expression = JSONValue(Fixture.$payload, "$.p") {
            Passing(2, as: "lim")
            Returning(.integer)
            DefaultOnEmpty(0)
            ErrorOnError()
        }

        check(
            expression,
            .psql(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' PASSING 2 AS \"lim\" RETURNING INTEGER DEFAULT 0 ON EMPTY ERROR ON ERROR)",
                "JSON_VALUE(\"documents\".\"payload\", $1 PASSING $2 AS \"lim\" RETURNING INTEGER DEFAULT 0 ON EMPTY ERROR ON ERROR)"
            )
        )

        let occurrences = completeOccurrences(
            of: expression.prepareObservingUnsafeValues(.psql)
        )
        #expect(occurrences.count == 3)
        #expect(occurrences[0].disposition == .bound(index: 0))
        #expect(occurrences[1].disposition == .bound(index: 1))
        #expect(occurrences[2].disposition == .notBound)
        #expect(occurrences[2].value as? Int == 0)

        let values = expression.prepare(.psql).splitted.values
        #expect(values.count == 2)
        #expect(values[1] as? Int == 2)
    }

    @Test("Values outside SQL/JSON scopes keep ordinary binding")
    func ordinaryValuesAreUnaffected() {
        let plain = Fn.coalesce(Fixture.$payload, "plain")
        check(
            plain,
            .psql(
                "coalesce(\"documents\".\"payload\",'plain')",
                "coalesce(\"documents\".\"payload\",$1)"
            )
        )
        #expect(plain.prepare(.psql).splitted.values[0] as? String == "plain")
        #expect(
            completeOccurrences(of: plain.prepareObservingUnsafeValues(.psql))
                .map(\.disposition) == [.bound(index: 0)]
        )

        // Duck does not opt into the contextual DEFAULT role at all.
        let duck = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty(0) }
        check(
            duck,
            .duck(
                "JSON_VALUE(\"documents\".\"payload\", '$.p' DEFAULT 0 ON EMPTY)",
                "JSON_VALUE(\"documents\".\"payload\", $1 DEFAULT $2 ON EMPTY)"
            )
        )
        #expect(duck.prepare(.duck).splitted.values.count == 2)
    }

    @Test("Custom dialect without contextual policy keeps ordinary binding")
    func customDialectCompatibility() {
        let expression = JSONValue(Fixture.$payload, "$.p") { DefaultOnEmpty(0) }

        let binding = SQLJSONCustomDialect()
        let values = expression.prepare(binding).splitted.values
        #expect(values.count == 2)
        #expect(values[0] as? String == "$.p")
        #expect(values[1] as? Int == 0)
        #expect(binding.seenRoles == ["path:jsonValue", "directRuntimeDefault:jsonValue"])

        let observing = SQLJSONCustomDialect()
        let occurrences = completeOccurrences(
            of: expression.prepareObservingUnsafeValues(observing)
        )
        #expect(occurrences.map(\.disposition) == [.bound(index: 0), .bound(index: 1)])
        #expect(observing.seenRoles == ["path:jsonValue", "directRuntimeDefault:jsonValue"])
    }

    @Test("Legacy JSON function rendering and binding are unchanged")
    func legacyJSONFunction() {
        check(
            Fn.jsonValue(Fixture.$payload, path: "$.name"),
            .psql(
                "json_value(\"documents\".\"payload\", '$.name')",
                "json_value(\"documents\".\"payload\", $1)"
            ),
            .mysql(
                "json_value(documents.payload, '$.name')",
                "json_value(documents.payload, ?)"
            ),
            .duck(
                "json_value(\"documents\".\"payload\", '$.name')",
                "json_value(\"documents\".\"payload\", $1)"
            )
        )
        #expect(
            Fn.jsonValue(Fixture.$payload, path: "$.name")
                .prepare(.mysql).splitted.values.count == 1
        )
    }

    @Test("A composed SELECT projects a SQL/JSON owner with bound path")
    func composedSelectProjection() {
        let query = Select {
            Fixture.$payload
            JSONValue(Fixture.$payload, "$.name") {
                Returning(.text)
                DefaultOnEmpty("anonymous")
            }
        }

        check(
            query,
            .psql(
                "SELECT \"documents\".\"payload\", JSON_VALUE(\"documents\".\"payload\", '$.name' RETURNING TEXT DEFAULT E'anonymous' ON EMPTY)",
                "SELECT \"documents\".\"payload\", JSON_VALUE(\"documents\".\"payload\", $1 RETURNING TEXT DEFAULT E'anonymous' ON EMPTY)"
            ),
            .mysql(
                "SELECT documents.payload, JSON_VALUE(documents.payload, '$.name' RETURNING TEXT DEFAULT _utf8mb4 X'616E6F6E796D6F7573' ON EMPTY)",
                "SELECT documents.payload, JSON_VALUE(documents.payload, ? RETURNING TEXT DEFAULT _utf8mb4 X'616E6F6E796D6F7573' ON EMPTY)"
            )
        )

        let values = query.prepare(.psql).splitted.values
        #expect(values.count == 1)
        #expect(values[0] as? String == "$.name")
    }
}
