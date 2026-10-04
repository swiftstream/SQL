import Foundation
import Testing
@testable import SQL

private func predicates(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> SwifQLable {
    body()
}

private func identifiers(
    @IdentifierListBuilder _ body: () -> IdentifierListBuilder.Components
) -> SwifQLable {
    body()
}

private final class PartsEvaluationLog {
    private(set) var events: [String] = []

    func append(_ label: String) {
        events.append(label)
    }
}

private final class CountingPartsChild: SwifQLable {
    private let payload: [SwifQLPart]
    private let label: String?
    private let log: PartsEvaluationLog?
    private(set) var partsEvaluationCount = 0

    init(payload: [SwifQLPart]) {
        self.payload = payload
        self.label = nil
        self.log = nil
    }

    init(label: String, payload: [SwifQLPart], log: PartsEvaluationLog) {
        self.payload = payload
        self.label = label
        self.log = log
    }

    var parts: [SwifQLPart] {
        partsEvaluationCount += 1
        if let label, let log {
            log.append(label)
        }
        return payload
    }
}

@Suite("Declarative query shared predicates")
struct DeclarativeQueryPredicateTests: SwifQLTests {
    // MARK: - P01 direct predicate default AND

    @Test("P01 direct predicate default AND")
    func p01DirectPredicateDefaultAND() {
        let two = predicates {
            \CarBrandReferences.$score == 10
            \CarBrandReferences.$model == "x001"
        }
        check(
            two,
            .psql(
                #""CarBrandReferences"."score" = 10 AND "CarBrandReferences"."model" = 'x001'"#,
                #""CarBrandReferences"."score" = $1 AND "CarBrandReferences"."model" = $2"#
            ),
            .mysql(
                "CarBrandReferences.score = 10 AND CarBrandReferences.model = 'x001'",
                "CarBrandReferences.score = ? AND CarBrandReferences.model = ?"
            ),
            .duck(
                #""CarBrandReferences"."score" = 10 AND "CarBrandReferences"."model" = 'x001'"#,
                #""CarBrandReferences"."score" = $1 AND "CarBrandReferences"."model" = $2"#
            )
        )

        // no outer parentheses for default AND
        #expect(!two.prepare(.psql).plain.hasPrefix("("))
        #expect(!two.prepare(.psql).plain.hasSuffix(")"))

        let three = predicates {
            \CarBrandReferences.$score == 10
            \CarBrandReferences.$model == "x001"
            \CarBrandReferences.$available == true
        }
        check(
            three,
            .psql(
                #""CarBrandReferences"."score" = 10 AND "CarBrandReferences"."model" = 'x001' AND "CarBrandReferences"."available" = TRUE"#,
                #""CarBrandReferences"."score" = $1 AND "CarBrandReferences"."model" = $2 AND "CarBrandReferences"."available" = TRUE"#
            )
        )
    }

    // MARK: - P02 empty predicate builder

    @Test("P02 empty predicate builder")
    func p02EmptyPredicateBuilder() {
        let empty = predicates {}
        #expect(empty.prepare(.psql).plain == "")
        #expect(empty.prepare(.mysql).plain == "")
        #expect(empty.prepare(.duck).plain == "")
        #expect(empty.prepare(.psql).splitted.values.isEmpty)
        #expect(empty.prepare(.mysql).splitted.values.isEmpty)
        #expect(empty.prepare(.duck).splitted.values.isEmpty)
    }

    // MARK: - P03 conditional omission

    @Test("P03 conditional omission")
    func p03ConditionalOmission() {
        let includeModel = true
        let present = predicates {
            \CarBrandReferences.$score == 10
            if includeModel {
                \CarBrandReferences.$model == "x001"
            }
        }
        check(
            present,
            .psql(
                #""CarBrandReferences"."score" = 10 AND "CarBrandReferences"."model" = 'x001'"#,
                #""CarBrandReferences"."score" = $1 AND "CarBrandReferences"."model" = $2"#
            )
        )

        let includeMissing = false
        let omitted = predicates {
            \CarBrandReferences.$score == 10
            if includeMissing {
                \CarBrandReferences.$model == "x001"
            }
        }
        check(
            omitted,
            .psql(
                #""CarBrandReferences"."score" = 10"#,
                #""CarBrandReferences"."score" = $1"#
            ),
            .mysql(
                "CarBrandReferences.score = 10",
                "CarBrandReferences.score = ?"
            ),
            .duck(
                #""CarBrandReferences"."score" = 10"#,
                #""CarBrandReferences"."score" = $1"#
            )
        )

        // no synthetic boolean
        #expect(!omitted.prepare(.psql).plain.contains("TRUE"))
        #expect(!omitted.prepare(.psql).plain.contains("FALSE"))
        #expect(!omitted.prepare(.psql).plain.contains("1 = 1"))
    }

    // MARK: - P04 if/else

    @Test("P04 if/else")
    func p04IfElse() {
        let preferModel = true
        let modelBranch = predicates {
            if preferModel {
                \CarBrandReferences.$model == "x001"
            } else {
                \CarBrandReferences.$score == 10
            }
        }
        check(
            modelBranch,
            .psql(
                #""CarBrandReferences"."model" = 'x001'"#,
                #""CarBrandReferences"."model" = $1"#
            )
        )

        let preferScore = false
        let scoreBranch = predicates {
            if preferScore {
                \CarBrandReferences.$model == "x001"
            } else {
                \CarBrandReferences.$score == 10
            }
        }
        check(
            scoreBranch,
            .psql(
                #""CarBrandReferences"."score" = 10"#,
                #""CarBrandReferences"."score" = $1"#
            )
        )
    }

    // MARK: - P05 for loop

    @Test("P05 for loop")
    func p05ForLoop() {
        let scores = [1, 2, 3]
        let built = predicates {
            \CarBrandReferences.$available == true
            for score in scores {
                \CarBrandReferences.$score == score
            }
        }
        check(
            built,
            .psql(
                #""CarBrandReferences"."available" = TRUE AND "CarBrandReferences"."score" = 1 AND "CarBrandReferences"."score" = 2 AND "CarBrandReferences"."score" = 3"#,
                #""CarBrandReferences"."available" = TRUE AND "CarBrandReferences"."score" = $1 AND "CarBrandReferences"."score" = $2 AND "CarBrandReferences"."score" = $3"#
            ),
            .mysql(
                "CarBrandReferences.available = TRUE AND CarBrandReferences.score = 1 AND CarBrandReferences.score = 2 AND CarBrandReferences.score = 3",
                "CarBrandReferences.available = TRUE AND CarBrandReferences.score = ? AND CarBrandReferences.score = ? AND CarBrandReferences.score = ?"
            ),
            .duck(
                #""CarBrandReferences"."available" = TRUE AND "CarBrandReferences"."score" = 1 AND "CarBrandReferences"."score" = 2 AND "CarBrandReferences"."score" = 3"#,
                #""CarBrandReferences"."available" = TRUE AND "CarBrandReferences"."score" = $1 AND "CarBrandReferences"."score" = $2 AND "CarBrandReferences"."score" = $3"#
            )
        )
    }

    // MARK: - P06 explicit And group

    @Test("P06 explicit And group")
    func p06ExplicitAndGroup() {
        let built = predicates {
            And {
                \CarBrandReferences.$score == 10
                \CarBrandReferences.$model == "x001"
            }
        }
        check(
            built,
            .psql(
                #"("CarBrandReferences"."score" = 10 AND "CarBrandReferences"."model" = 'x001')"#,
                #"("CarBrandReferences"."score" = $1 AND "CarBrandReferences"."model" = $2)"#
            ),
            .mysql(
                "(CarBrandReferences.score = 10 AND CarBrandReferences.model = 'x001')",
                "(CarBrandReferences.score = ? AND CarBrandReferences.model = ?)"
            ),
            .duck(
                #"("CarBrandReferences"."score" = 10 AND "CarBrandReferences"."model" = 'x001')"#,
                #"("CarBrandReferences"."score" = $1 AND "CarBrandReferences"."model" = $2)"#
            )
        )
    }

    // MARK: - P07 explicit Or group

    @Test("P07 explicit Or group")
    func p07ExplicitOrGroup() {
        let built = predicates {
            Or {
                \CarBrandReferences.$score == 10
                \CarBrandReferences.$score == 20
            }
        }
        check(
            built,
            .psql(
                #"("CarBrandReferences"."score" = 10 OR "CarBrandReferences"."score" = 20)"#,
                #"("CarBrandReferences"."score" = $1 OR "CarBrandReferences"."score" = $2)"#
            ),
            .mysql(
                "(CarBrandReferences.score = 10 OR CarBrandReferences.score = 20)",
                "(CarBrandReferences.score = ? OR CarBrandReferences.score = ?)"
            ),
            .duck(
                #"("CarBrandReferences"."score" = 10 OR "CarBrandReferences"."score" = 20)"#,
                #"("CarBrandReferences"."score" = $1 OR "CarBrandReferences"."score" = $2)"#
            )
        )
    }

    // MARK: - P08 nested And/Or precedence

    @Test("P08 nested And/Or precedence")
    func p08NestedAndOrPrecedence() {
        let built = predicates {
            \CarBrandReferences.$available == true
            Or {
                \CarBrandReferences.$score == 10
                And {
                    \CarBrandReferences.$model == "x001"
                    \CarBrandReferences.$score == 20
                }
            }
        }
        check(
            built,
            .psql(
                #""CarBrandReferences"."available" = TRUE AND ("CarBrandReferences"."score" = 10 OR ("CarBrandReferences"."model" = 'x001' AND "CarBrandReferences"."score" = 20))"#,
                #""CarBrandReferences"."available" = TRUE AND ("CarBrandReferences"."score" = $1 OR ("CarBrandReferences"."model" = $2 AND "CarBrandReferences"."score" = $3))"#
            ),
            .mysql(
                "CarBrandReferences.available = TRUE AND (CarBrandReferences.score = 10 OR (CarBrandReferences.model = 'x001' AND CarBrandReferences.score = 20))",
                "CarBrandReferences.available = TRUE AND (CarBrandReferences.score = ? OR (CarBrandReferences.model = ? AND CarBrandReferences.score = ?))"
            ),
            .duck(
                #""CarBrandReferences"."available" = TRUE AND ("CarBrandReferences"."score" = 10 OR ("CarBrandReferences"."model" = 'x001' AND "CarBrandReferences"."score" = 20))"#,
                #""CarBrandReferences"."available" = TRUE AND ("CarBrandReferences"."score" = $1 OR ("CarBrandReferences"."model" = $2 AND "CarBrandReferences"."score" = $3))"#
            )
        )
    }

    // MARK: - P09 nested bind order

    @Test("P09 nested bind order")
    func p09NestedBindOrder() {
        let roles = ["admin", "moderator"]
        let built = predicates {
            \CarBrandReferences.$model == "primary"
            if let first = roles.first {
                \CarBrandReferences.$model == first
            }
            Or {
                for role in roles {
                    \CarBrandReferences.$model == role
                }
            }
        }

        let psql = built.prepare(.psql)
        #expect(
            psql.splitted.query ==
                #""CarBrandReferences"."model" = $1 AND "CarBrandReferences"."model" = $2 AND ("CarBrandReferences"."model" = $3 OR "CarBrandReferences"."model" = $4)"#
        )
        #expect(psql.splitted.values.map { "\($0)" } == ["primary", "admin", "admin", "moderator"])

        let mysql = built.prepare(.mysql)
        #expect(
            mysql.splitted.query ==
                "CarBrandReferences.model = ? AND CarBrandReferences.model = ? AND (CarBrandReferences.model = ? OR CarBrandReferences.model = ?)"
        )
        #expect(mysql.splitted.values.map { "\($0)" } == ["primary", "admin", "admin", "moderator"])

        let duck = built.prepare(.duck)
        #expect(
            duck.splitted.query ==
                #""CarBrandReferences"."model" = $1 AND "CarBrandReferences"."model" = $2 AND ("CarBrandReferences"."model" = $3 OR "CarBrandReferences"."model" = $4)"#
        )
        #expect(duck.splitted.values.map { "\($0)" } == ["primary", "admin", "admin", "moderator"])

        // preparation-observation equivalence
        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let observed = built.prepareObservingUnsafeValues(dialect).prepared
            let regular = built.prepare(dialect)
            #expect(observed.plain == regular.plain)
            #expect(observed.splitted.query == regular.splitted.query)
            #expect(
                observed.splitted.values.map { "\($0)" }
                    == regular.splitted.values.map { "\($0)" }
            )
        }
    }

    // MARK: - P10 empty And/Or omission

    @Test("P10 empty And/Or omission")
    func p10EmptyAndOrOmission() {
        let built = predicates {
            \CarBrandReferences.$score == 10
            And {}
            Or {}
        }
        check(
            built,
            .psql(
                #""CarBrandReferences"."score" = 10"#,
                #""CarBrandReferences"."score" = $1"#
            ),
            .mysql(
                "CarBrandReferences.score = 10",
                "CarBrandReferences.score = ?"
            ),
            .duck(
                #""CarBrandReferences"."score" = 10"#,
                #""CarBrandReferences"."score" = $1"#
            )
        )
        #expect(!built.prepare(.psql).plain.contains("()"))
        #expect(!built.prepare(.psql).plain.contains("AND ()"))
        #expect(!built.prepare(.psql).plain.contains("OR ()"))

        let onlyEmpty = predicates {
            And {}
            Or {}
        }
        #expect(onlyEmpty.prepare(.psql).plain == "")
        #expect(onlyEmpty.prepare(.psql).splitted.values.isEmpty)
    }

    // MARK: - P11 IsNull / IsNotNull equivalence

    @Test("P11 IsNull / IsNotNull equivalence")
    func p11NullEquivalence() {
        let lhs = \CarBrandReferences.$model

        let isNull = IsNull(lhs)
        let equalNil = lhs == nil
        let fluentIsNull = lhs.isNull
        check(
            isNull,
            .psql(
                #""CarBrandReferences"."model" IS NULL"#,
                #""CarBrandReferences"."model" IS NULL"#
            ),
            .mysql("CarBrandReferences.model IS NULL"),
            .duck(#""CarBrandReferences"."model" IS NULL"#)
        )
        #expect(isNull.prepare(.psql).plain == equalNil.prepare(.psql).plain)
        #expect(isNull.prepare(.psql).splitted.query == equalNil.prepare(.psql).splitted.query)
        #expect(isNull.prepare(.psql).plain == fluentIsNull.prepare(.psql).plain)
        #expect(isNull.prepare(.mysql).plain == equalNil.prepare(.mysql).plain)
        #expect(isNull.prepare(.mysql).plain == fluentIsNull.prepare(.mysql).plain)
        #expect(isNull.prepare(.duck).plain == equalNil.prepare(.duck).plain)
        #expect(isNull.prepare(.duck).plain == fluentIsNull.prepare(.duck).plain)
        #expect(isNull.prepare(.psql).splitted.values.isEmpty)

        let isNotNull = IsNotNull(lhs)
        let notEqualNil = lhs != nil
        let fluentIsNotNull = lhs.isNotNull
        check(
            isNotNull,
            .psql(
                #""CarBrandReferences"."model" IS NOT NULL"#,
                #""CarBrandReferences"."model" IS NOT NULL"#
            ),
            .mysql("CarBrandReferences.model IS NOT NULL"),
            .duck(#""CarBrandReferences"."model" IS NOT NULL"#)
        )
        #expect(isNotNull.prepare(.psql).plain == notEqualNil.prepare(.psql).plain)
        #expect(isNotNull.prepare(.psql).splitted.query == notEqualNil.prepare(.psql).splitted.query)
        #expect(isNotNull.prepare(.mysql).plain == notEqualNil.prepare(.mysql).plain)
        #expect(isNotNull.prepare(.duck).plain == notEqualNil.prepare(.duck).plain)
        // legacy .isNotNull appends a trailing operator space after IS NOT NULL;
        // semantic SQL identity is asserted against the operator core.
        #expect(
            fluentIsNotNull.prepare(.psql).plain.trimmingCharacters(in: .whitespaces)
                == isNotNull.prepare(.psql).plain.trimmingCharacters(in: .whitespaces)
        )
        #expect(isNotNull.prepare(.psql).splitted.values.isEmpty)

        // existing boolean operators and legacy NULL surfaces remain available
        let combined = lhs == nil && lhs != nil
        #expect(combined.prepare(.psql).plain.contains("IS NULL"))
        #expect(combined.prepare(.psql).plain.contains("IS NOT NULL"))
    }

    // MARK: - P12 runtime In non-empty

    @Test("P12 runtime In non-empty")
    func p12RuntimeInNonEmpty() {
        let values = [1, 2, 3]
        let built = In(\CarBrandReferences.$score, values)
        check(
            built,
            .psql(
                #""CarBrandReferences"."score" IN (1, 2, 3)"#,
                #""CarBrandReferences"."score" IN ($1, $2, $3)"#
            ),
            .mysql(
                "CarBrandReferences.score IN (1, 2, 3)",
                "CarBrandReferences.score IN (?, ?, ?)"
            ),
            .duck(
                #""CarBrandReferences"."score" IN (1, 2, 3)"#,
                #""CarBrandReferences"."score" IN ($1, $2, $3)"#
            )
        )
        let psql = built.prepare(.psql)
        #expect(psql.splitted.values.map { "\($0)" } == ["1", "2", "3"])
        let mysql = built.prepare(.mysql)
        #expect(mysql.splitted.values.map { "\($0)" } == ["1", "2", "3"])

        // Stateful evaluation-order proof: lhs before items; each getter exactly once.
        let log = PartsEvaluationLog()
        let statefulLHS = CountingPartsChild(
            label: "lhs",
            payload: [
                SwifQLPartKeyPath(schema: "CarBrandReferences", table: "CarBrandReferences", paths: ["score"])
            ],
            log: log
        )
        let item1 = CountingPartsChild(label: "item-1", payload: [SwifQLPartUnsafeValue(10)], log: log)
        let item2 = CountingPartsChild(label: "item-2", payload: [SwifQLPartUnsafeValue(20)], log: log)
        let stateful = In(statefulLHS, [item1, item2])

        #expect(log.events == ["lhs", "item-1", "item-2"])
        #expect(statefulLHS.partsEvaluationCount == 1)
        #expect(item1.partsEvaluationCount == 1)
        #expect(item2.partsEvaluationCount == 1)

        let statefulPrepared = stateful.prepare(.psql)
        #expect(
            statefulPrepared.splitted.query
                == #""CarBrandReferences"."CarBrandReferences"."score" IN ($1, $2)"#
        )
        #expect(statefulPrepared.splitted.values.map { "\($0)" } == ["10", "20"])

        // Snapshots retained: preparation causes zero re-evaluation.
        #expect(log.events == ["lhs", "item-1", "item-2"])
        #expect(statefulLHS.partsEvaluationCount == 1)
        #expect(item1.partsEvaluationCount == 1)
        #expect(item2.partsEvaluationCount == 1)
    }

    // MARK: - P13 runtime In empty omission

    @Test("P13 runtime In empty omission")
    func p13RuntimeInEmptyOmission() {
        let counting = CountingPartsChild(payload: [
            SwifQLPartKeyPath(schema: "CarBrandReferences", table: "CarBrandReferences", paths: ["score"])
        ])
        let empty: [Int] = []
        let built = In(counting, empty)

        #expect(counting.partsEvaluationCount == 0)
        #expect(built.prepare(.psql).plain == "")
        #expect(built.prepare(.mysql).plain == "")
        #expect(built.prepare(.duck).plain == "")
        #expect(built.prepare(.psql).splitted.values.isEmpty)
        #expect(built.prepare(.mysql).splitted.values.isEmpty)
        #expect(built.prepare(.duck).splitted.values.isEmpty)
        #expect(counting.partsEvaluationCount == 0)
        #expect(!built.prepare(.psql).plain.contains("IN"))
        #expect(!built.prepare(.psql).plain.contains("TRUE"))
        #expect(!built.prepare(.psql).plain.contains("FALSE"))

        // legacy lowercase empty membership remains unchanged (still emits IN ())
        let legacy = counting.in([])
        #expect(counting.partsEvaluationCount > 0)
        #expect(legacy.prepare(.psql).plain.contains("IN"))
    }

    // MARK: - P14 runtime NotIn non-empty/empty

    @Test("P14 runtime NotIn non-empty/empty")
    func p14RuntimeNotInNonEmptyEmpty() {
        let values = [1, 2]
        let nonEmpty = NotIn(\CarBrandReferences.$score, values)
        check(
            nonEmpty,
            .psql(
                #""CarBrandReferences"."score" NOT IN (1, 2)"#,
                #""CarBrandReferences"."score" NOT IN ($1, $2)"#
            ),
            .mysql(
                "CarBrandReferences.score NOT IN (1, 2)",
                "CarBrandReferences.score NOT IN (?, ?)"
            ),
            .duck(
                #""CarBrandReferences"."score" NOT IN (1, 2)"#,
                #""CarBrandReferences"."score" NOT IN ($1, $2)"#
            )
        )
        #expect(nonEmpty.prepare(.psql).splitted.values.map { "\($0)" } == ["1", "2"])

        // Stateful evaluation-order proof: lhs before items; each getter exactly once.
        let log = PartsEvaluationLog()
        let statefulLHS = CountingPartsChild(
            label: "lhs",
            payload: [
                SwifQLPartKeyPath(schema: "CarBrandReferences", table: "CarBrandReferences", paths: ["score"])
            ],
            log: log
        )
        let item1 = CountingPartsChild(label: "item-1", payload: [SwifQLPartUnsafeValue(10)], log: log)
        let item2 = CountingPartsChild(label: "item-2", payload: [SwifQLPartUnsafeValue(20)], log: log)
        let stateful = NotIn(statefulLHS, [item1, item2])

        #expect(log.events == ["lhs", "item-1", "item-2"])
        #expect(statefulLHS.partsEvaluationCount == 1)
        #expect(item1.partsEvaluationCount == 1)
        #expect(item2.partsEvaluationCount == 1)

        let statefulPrepared = stateful.prepare(.psql)
        #expect(
            statefulPrepared.splitted.query
                == #""CarBrandReferences"."CarBrandReferences"."score" NOT IN ($1, $2)"#
        )
        #expect(statefulPrepared.splitted.values.map { "\($0)" } == ["10", "20"])

        // Snapshots retained: preparation causes zero re-evaluation.
        #expect(log.events == ["lhs", "item-1", "item-2"])
        #expect(statefulLHS.partsEvaluationCount == 1)
        #expect(item1.partsEvaluationCount == 1)
        #expect(item2.partsEvaluationCount == 1)

        let counting = CountingPartsChild(payload: [
            SwifQLPartKeyPath(schema: "CarBrandReferences", table: "CarBrandReferences", paths: ["score"])
        ])
        let empty: [Int] = []
        let omitted = NotIn(counting, empty)
        #expect(counting.partsEvaluationCount == 0)
        #expect(omitted.prepare(.psql).plain == "")
        #expect(omitted.prepare(.mysql).plain == "")
        #expect(omitted.prepare(.duck).plain == "")
        #expect(omitted.prepare(.psql).splitted.values.isEmpty)
        #expect(counting.partsEvaluationCount == 0)
        #expect(!omitted.prepare(.psql).plain.contains("NOT IN"))
        #expect(!omitted.prepare(.psql).plain.contains("TRUE"))
        #expect(!omitted.prepare(.psql).plain.contains("FALSE"))

        // legacy lowercase empty membership remains unchanged
        let legacy = counting.notIn([])
        #expect(counting.partsEvaluationCount > 0)
        #expect(legacy.prepare(.psql).plain.contains("NOT IN"))
    }

    // MARK: - P15 identifier list

    @Test("P15 identifier list")
    func p15IdentifierList() {
        let direct = identifiers {
            "id"
            "email"
        }
        #expect(direct.prepare(.psql).plain == #""id", "email""#)
        #expect(direct.prepare(.mysql).plain == "id, email")
        #expect(direct.prepare(.duck).plain == #""id", "email""#)
        #expect(direct.prepare(.psql).splitted.values.count == 0)
        #expect(direct.prepare(.mysql).splitted.values.count == 0)
        #expect(direct.prepare(.duck).splitted.values.count == 0)

        let maybe: String? = "createdAt"
        let dynamic = identifiers {
            "id"
            if let maybe {
                maybe
            }
            for name in ["a", "b"] {
                name
            }
        }
        #expect(dynamic.prepare(.psql).plain == #""id", "createdAt", "a", "b""#)
        #expect(dynamic.prepare(.mysql).plain == "id, createdAt, a, b")
        #expect(dynamic.prepare(.duck).plain == #""id", "createdAt", "a", "b""#)
        #expect(dynamic.prepare(.psql).splitted.values.count == 0)

        let omitted = identifiers {
            "id"
            if false {
                "email"
            }
        }
        #expect(omitted.prepare(.psql).plain == #""id""#)

        let empty = identifiers {}
        #expect(empty.prepare(.psql).plain == "")
        #expect(empty.prepare(.mysql).plain == "")
        #expect(empty.prepare(.duck).plain == "")
        #expect(empty.prepare(.psql).splitted.values.isEmpty)

        // identifier quoting is alias/identifier-safe, never String value semantics
        #expect(!direct.prepare(.psql).plain.contains("'id'"))
        #expect(!direct.prepare(.mysql).plain.contains("'id'"))
        #expect(!direct.prepare(.duck).plain.contains("'id'"))
    }

    // MARK: - P16 typed As positive substrate

    @Test("P16 typed As positive substrate")
    func p16TypedAsPositiveSubstrate() {
        let request = As("alias")
        #expect(request.name == "alias")

        // straight-line: open aliasable probe + As transitions to distinct aliased type
        let straight = ProbeSelect {
            ProbeOpen(token: "id")
            As("identifier")

            ProbeOpen(token: "email")
            As("emailAddress")
        }
        #expect(straight.prepare(.psql).plain == #"id as "identifier", email as "emailAddress""#)
        #expect(straight.prepare(.mysql).plain == "id as identifier, email as emailAddress")
        #expect(straight.prepare(.duck).plain == #"id as "identifier", email as "emailAddress""#)

        // branch-local alias continuation
        let includeEmail = true
        let branchTrue = ProbeSelect {
            ProbeOpen(token: "id")
            if includeEmail {
                ProbeOpen(token: "email")
                As("emailAddress")
            }
        }
        #expect(branchTrue.prepare(.psql).plain == #"id, email as "emailAddress""#)

        let includeMissing = false
        let branchFalse = ProbeSelect {
            ProbeOpen(token: "id")
            if includeMissing {
                ProbeOpen(token: "email")
                As("emailAddress")
            }
        }
        #expect(branchFalse.prepare(.psql).plain == "id")

        // production AliasRequest + AliasableItem are sufficient; probe is test-only
        #expect(type(of: request) == SQLBuilder.AliasRequest.self)
    }
}

// MARK: - P16 test-only typed As probe (not production API)

private struct ProbeOpen: SQLBuilder.AliasableItem {
    typealias Aliased = ProbeAliased

    let token: String

    func finalize() -> SwifQLable {
        SwifQLableParts(parts: SwifQLPartOperator.custom(token))
    }

    func addingAlias(_ name: String) -> ProbeAliased {
        ProbeAliased(token: token, alias: name)
    }
}

private struct ProbeAliased: SQLBuilder.FinalizableItem {
    let token: String
    let alias: String

    func finalize() -> SwifQLable {
        var parts: [SwifQLPart] = [SwifQLPartOperator.custom(token)]
        parts.append(o: .space)
        parts.append(o: .as)
        parts.append(o: .space)
        parts.append(SwifQLPartAlias(alias))
        return SwifQLableParts(rawParts: parts)
    }
}

@resultBuilder
private enum ProbeAliasBuilder {
    struct Partial<Current: SQLBuilder.FinalizableItem> {
        var completed: [SwifQLable]
        var current: Current
    }

    struct FinalizedGroup<Source: SQLBuilder.FinalizableItem> {
        let fragments: [SwifQLable]
    }

    static func buildPartialBlock<C: SQLBuilder.AliasableItem>(
        first current: C
    ) -> Partial<C> {
        Partial(completed: [], current: current)
    }

    static func buildPartialBlock<C: SQLBuilder.FinalizableItem, D: SQLBuilder.AliasableItem>(
        accumulated: Partial<C>,
        next: D
    ) -> Partial<D> {
        Partial(
            completed: accumulated.completed + [accumulated.current.finalize()],
            current: next
        )
    }

    static func buildPartialBlock<C: SQLBuilder.AliasableItem>(
        accumulated: Partial<C>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<C.Aliased> {
        Partial(
            completed: accumulated.completed,
            current: accumulated.current.addingAlias(next.name)
        )
    }

    static func buildOptional<C: SQLBuilder.FinalizableItem>(
        _ component: Partial<C>?
    ) -> FinalizedGroup<C>? {
        component.map {
            FinalizedGroup<C>(fragments: $0.completed + [$0.current.finalize()])
        }
    }

    static func buildEither<C: SQLBuilder.FinalizableItem>(
        first component: Partial<C>
    ) -> FinalizedGroup<C> {
        FinalizedGroup<C>(fragments: component.completed + [component.current.finalize()])
    }

    static func buildEither<C: SQLBuilder.FinalizableItem>(
        second component: Partial<C>
    ) -> FinalizedGroup<C> {
        FinalizedGroup<C>(fragments: component.completed + [component.current.finalize()])
    }

    static func buildArray<C: SQLBuilder.FinalizableItem>(
        _ components: [Partial<C>]
    ) -> FinalizedGroup<C> {
        FinalizedGroup<C>(
            fragments: components.flatMap { $0.completed + [$0.current.finalize()] }
        )
    }

    static func buildPartialBlock<C: SQLBuilder.FinalizableItem, Source: SQLBuilder.FinalizableItem>(
        accumulated: Partial<C>,
        next: FinalizedGroup<Source>
    ) -> Partial<SQLBuilder.NeutralItem> {
        let fragments = accumulated.completed + [accumulated.current.finalize()] + next.fragments
        return Partial(
            completed: [],
            current: SQLBuilder.NeutralItem(snapshotting: join(fragments))
        )
    }

    static func buildPartialBlock<C: SQLBuilder.FinalizableItem, Source: SQLBuilder.FinalizableItem>(
        accumulated: Partial<C>,
        next: FinalizedGroup<Source>?
    ) -> Partial<SQLBuilder.NeutralItem> {
        let fragments = accumulated.completed + [accumulated.current.finalize()] + (next?.fragments ?? [])
        return Partial(
            completed: [],
            current: SQLBuilder.NeutralItem(snapshotting: join(fragments))
        )
    }

    static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        first group: FinalizedGroup<Source>
    ) -> Partial<SQLBuilder.NeutralItem> {
        Partial(
            completed: [],
            current: SQLBuilder.NeutralItem(snapshotting: join(group.fragments))
        )
    }

    static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        first group: FinalizedGroup<Source>?
    ) -> Partial<SQLBuilder.NeutralItem> {
        Partial(
            completed: [],
            current: SQLBuilder.NeutralItem(snapshotting: join(group?.fragments ?? []))
        )
    }

    static func buildFinalResult<C: SQLBuilder.FinalizableItem>(
        _ component: Partial<C>
    ) -> SwifQLable {
        SwifQLableParts(rawParts: join(component.completed + [component.current.finalize()]))
    }

    static func buildFinalResult<Source: SQLBuilder.FinalizableItem>(
        _ component: FinalizedGroup<Source>
    ) -> SwifQLable {
        SwifQLableParts(rawParts: join(component.fragments))
    }

    static func buildFinalResult<Source: SQLBuilder.FinalizableItem>(
        _ component: FinalizedGroup<Source>?
    ) -> SwifQLable {
        SwifQLableParts(rawParts: join(component?.fragments ?? []))
    }

    private static func join(_ fragments: [SwifQLable]) -> [SwifQLPart] {
        var parts: [SwifQLPart] = []
        for (index, fragment) in fragments.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: fragment.parts)
        }
        return parts
    }
}

private struct ProbeSelect {
    let sql: SwifQLable

    init(@ProbeAliasBuilder _ body: () -> SwifQLable) {
        sql = body()
    }

    var parts: [SwifQLPart] { sql.parts }
}

extension ProbeSelect: SwifQLable {}
