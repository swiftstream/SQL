@testable import SQL
import Testing

private extension Fn.Name {
    static let weightedSumEF01: Self = .init("weighted_sum")
    static var pairAggEF01: Self { .init("pair_agg") }
}

private extension Fn {
    static func weightedSumEF01(
        @AggregateArgumentBuilder _ body: () -> AggregateArguments
    ) -> SQLable {
        aggregate(.weightedSumEF01, body)
    }
}

@Suite("Aggregate Argument Builder Tests")
struct AggregateArgumentBuilderTests: SwifQLTests {
    @Test("Generic aggregate supports regular zero and star arguments")
    func genericBasics() {
        let one = Fn.aggregate(.weightedSumEF01) {
            DB.Column("value")
        }
        let multiple = Fn.aggregate(.weightedSumEF01) {
            DB.Column("value")
            DB.Column("weight")
        }
        let zero = Fn.aggregate(.custom("zero_agg")) {}
        let star = Fn.aggregate(.custom("my_count")) {
            SQL.asterisk
        }

        #expect(one.prepare(.psql).plain == #"weighted_sum("value")"#)
        #expect(multiple.prepare(.psql).plain == #"weighted_sum("value", "weight")"#)
        #expect(zero.prepare(.psql).plain == "zero_agg()")
        #expect(star.prepare(.psql).plain == "my_count(*)")
    }

    @Test("Plain Distinct supports concise builder and andAlso forms")
    func distinctForms() {
        let concise = Fn.aggregate(.pairAggEF01) {
            Distinct(DB.Column("a"), DB.Column("b"))
        }
        let built = Fn.aggregate(.pairAggEF01) {
            Distinct {
                DB.Column("a")
                DB.Column("b")
            }
        }
        let extended = Fn.aggregate(.pairAggEF01) {
            Distinct(DB.Column("a")).andAlso(DB.Column("b"))
        }

        for expression in [concise, built, extended] {
            #expect(expression.prepare(.psql).plain == #"pair_agg(DISTINCT "a", "b")"#)
        }
    }

    @Test("Aggregate local ORDER BY follows regular arguments without a comma")
    func regularOrderBy() {
        let expression = Fn.weightedSumEF01 {
            DB.Column("value")
            DB.Column("weight")
            OrderBy(DB.Column("timestamp"), .desc)
        }

        #expect(
            expression.prepare(.psql).plain
                == #"weighted_sum("value", "weight" ORDER BY "timestamp" DESC)"#
        )
    }

    @Test("Aggregate local ORDER BY follows Distinct ownership")
    func distinctOrderBy() {
        let expression = Fn.aggregate(.custom("my_agg")) {
            Distinct {
                DB.Column("value")
            }
            OrderBy(DB.Column("value"), .asc)
        }

        #expect(
            expression.prepare(.psql).plain
                == #"my_agg(DISTINCT "value" ORDER BY "value" ASC)"#
        )
    }

    @Test("Dynamic regular versus Distinct branch preserves complete ownership")
    func dynamicOwnershipBranch() {
        for deduplicate in [true, false] {
            let expression = Fn.aggregate(.custom("my_agg")) {
                if deduplicate {
                    Distinct(DB.Column("value"))
                } else {
                    DB.Column("value")
                }
                OrderBy(DB.Column("value"), .desc)
            }

            let expected = deduplicate
                ? #"my_agg(DISTINCT "value" ORDER BY "value" DESC)"#
                : #"my_agg("value" ORDER BY "value" DESC)"#

            #expect(expression.prepare(.psql).plain == expected)
        }
    }

    @Test("Regular optional and loop expressions preserve source order")
    func regularControlFlow() {
        let includeMiddle = true
        let tail = [3, 4]

        let expression = Fn.aggregate(.custom("my_agg")) {
            1
            if includeMiddle {
                2
            }
            for value in tail {
                value
            }
        }

        #expect(expression.prepare(.psql).plain == "my_agg(1, 2, 3, 4)")
    }

    @Test("Bind order is arguments then aggregate local order")
    func bindOrder() {
        let first = SQLableParts(parts: SQLPartUnsafeValue(10))
        let second = SQLableParts(parts: SQLPartUnsafeValue(20))
        let ordered = SQLableParts(parts: SQLPartUnsafeValue(30))

        let expression = Fn.aggregate(.weightedSumEF01) {
            first
            second
            OrderBy(ordered, .desc)
        }

        let postgres = expression.prepare(.psql)
        #expect(postgres.splitted.query == "weighted_sum($1, $2 ORDER BY $3 DESC)")
        #expect(postgres.splitted.values.count == 3)
        #expect(postgres.splitted.values[0] as? Int == 10)
        #expect(postgres.splitted.values[1] as? Int == 20)
        #expect(postgres.splitted.values[2] as? Int == 30)

        let duck = expression.prepare(.duck)
        #expect(duck.splitted.query == "weighted_sum($1, $2 ORDER BY $3 DESC)")
        #expect(duck.splitted.values.count == 3)

        let mysql = expression.prepare(.mysql)
        #expect(mysql.splitted.query == "weighted_sum(?, ? ORDER BY ? DESC)")
        #expect(mysql.splitted.values.count == 3)
    }

    @Test("Existential SQLable ingress remains accepted")
    func existentialIngress() {
        let value: any SQLable = DB.Column("value")
        let expression = Fn.sum {
            value
        }

        #expect(expression.prepare(.psql).plain == #"sum("value")"#)
    }

    @Test("All nine built in aggregate builder overloads render")
    func builtInOverloads() {
        let value = DB.Column("value")

        #expect(Fn.arrayAgg { value }.prepare(.psql).plain == #"array_agg("value")"#)
        #expect(Fn.avg { value }.prepare(.psql).plain == #"avg("value")"#)
        #expect(Fn.count { value }.prepare(.psql).plain == #"count("value")"#)
        #expect(Fn.max { value }.prepare(.psql).plain == #"max("value")"#)
        #expect(Fn.min { value }.prepare(.psql).plain == #"min("value")"#)
        #expect(Fn.sum { value }.prepare(.psql).plain == #"sum("value")"#)
        #expect(
            Fn.stringAgg {
                value
                ","
            }.prepare(.psql).plain == #"string_agg("value", ',')"#
        )
        #expect(Fn.boolAnd { value }.prepare(.psql).plain == #"bool_and("value")"#)
        #expect(Fn.boolOr { value }.prepare(.psql).plain == #"bool_or("value")"#)
    }

    @Test("Existing concise aggregate overloads retain parity")
    func conciseParity() {
        let value = DB.Column("value")

        let pairs: [(any SQLable, any SQLable)] = [
            (Fn.arrayAgg(value), Fn.arrayAgg { value }),
            (Fn.avg(value), Fn.avg { value }),
            (Fn.count(value), Fn.count { value }),
            (Fn.max(value), Fn.max { value }),
            (Fn.min(value), Fn.min { value }),
            (Fn.sum(value), Fn.sum { value }),
            (Fn.stringAgg(value, ","), Fn.stringAgg { value; "," }),
            (Fn.boolAnd(value), Fn.boolAnd { value }),
            (Fn.boolOr(value), Fn.boolOr { value })
        ]

        for (concise, built) in pairs {
            for dialect in [SQLDialect.psql, .mysql, .duck] {
                #expect(concise.prepare(dialect).plain == built.prepare(dialect).plain)
            }
        }
    }

    @Test("count star and empty body remain distinct")
    func countStarAndEmpty() {
        #expect(Fn.count().prepare(.psql).plain == "count(*)")
        #expect(Fn.count { SQL.asterisk }.prepare(.psql).plain == "count(*)")
        #expect(Fn.count {}.prepare(.psql).plain == "count()")
    }

    @Test("Fn build remains a separate scalar primitive")
    func fnBuildCoexistence() {
        let scalar = Fn.build(
            .custom("scalar"),
            body: DB.Column("value").parts
        )
        let emptyScalar = Fn.build(.custom("scalar"))

        #expect(scalar.prepare(.psql).plain == #"scalar("value")"#)
        #expect(emptyScalar.prepare(.psql).plain == "scalar")
    }

    @Test("Aggregate results compose with filter over and alias")
    func postfixComposition() {
        let value = DB.Column("value")
        let aggregate = Fn.sum { value }

        #expect(
            aggregate
                .filter(where: value > 0)
                .prepare(.psql).plain
                == #"sum("value") FILTER (WHERE "value" > 0)"#
        )
        #expect(
            aggregate
                .over(partitionBy: DB.Column("group"))
                .prepare(.psql).plain
                == #"sum("value") OVER (PARTITION BY "group")"#
        )
        #expect(
            aggregate
                .as("total")
                .prepare(.psql).plain
                == #"sum("value") as "total""#
        )
    }

    @Test("Aggregate array result reuses Wave 04 subscript grouping")
    func aggregateSubscriptGrouping() {
        let expression = Fn.arrayAgg {
            DB.Column("score")
        }[1]

        #expect(
            expression.prepare(.psql).plain
                == #"(array_agg("score"))[1]"#
        )
        #expect(
            expression.prepare(.duck).plain
                == #"array_agg("score")[1]"#
        )
    }

    @Test("OrderBy preserves multiple item source order")
    func multipleOrderItems() {
        let expression = Fn.arrayAgg {
            DB.Column("value")
            OrderBy {
                OrderByItem.desc(DB.Column("createdAt"))
                OrderByItem.asc(DB.Column("id"))
            }
        }

        #expect(
            expression.prepare(.psql).plain
                == #"array_agg("value" ORDER BY "createdAt" DESC, "id" ASC)"#
        )
    }
}
