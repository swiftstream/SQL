import Foundation
import Testing
@testable import SQL

private final class ClausePredicatePartsProbe: SwifQLable {
    private(set) var partsReadCount = 0

    var parts: [SwifQLPart] {
        partsReadCount += 1
        return [SwifQLPartOperator.custom("TRUE")]
    }
}

@Suite("Declarative query core clauses")
struct DeclarativeQueryClauseTests: SwifQLTests {
    @Test("DQ05.3 WHERE joins direct predicates with AND and preserves grouped OR bind order")
    func whereDefaultAndGroups() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where {
                Path.Column("age") >= 18
                Or {
                    Path.Column("role") == "admin"
                    Path.Column("role") == "editor"
                }
            }
        }

        let psql = query.prepare(.psql)
        #expect(psql.plain == #"SELECT "id" FROM "User" WHERE "age" >= 18 AND ("role" = 'admin' OR "role" = 'editor')"#)
        #expect(psql.splitted.query == #"SELECT "id" FROM "User" WHERE "age" >= $1 AND ("role" = $2 OR "role" = $3)"#)
        #expect(psql.splitted.values.map { String(describing: $0) } == ["18", "admin", "editor"])

        let mysql = query.prepare(.mysql)
        #expect(mysql.plain == "SELECT id FROM User WHERE age >= 18 AND (role = 'admin' OR role = 'editor')")
        #expect(mysql.splitted.query == "SELECT id FROM User WHERE age >= ? AND (role = ? OR role = ?)")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["18", "admin", "editor"])

        let duck = query.prepare(.duck)
        #expect(duck.plain == #"SELECT "id" FROM "User" WHERE "age" >= 18 AND ("role" = 'admin' OR "role" = 'editor')"#)
        #expect(duck.splitted.query == #"SELECT "id" FROM "User" WHERE "age" >= $1 AND ("role" = $2 OR "role" = $3)"#)
        #expect(duck.splitted.values.map { String(describing: $0) } == ["18", "admin", "editor"])
    }

    @Test("DQ05.3 explicit And and Or groups remain parenthesized in source order")
    func explicitBooleanGroups() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where {
                And {
                    Path.Column("a") == 1
                    Path.Column("b") == 2
                }
                Or {
                    Path.Column("c") == 3
                    Path.Column("d") == 4
                }
            }
        }

        let prepared = query.prepare(.psql)
        #expect(prepared.plain == #"SELECT "id" FROM "User" WHERE ("a" = 1 AND "b" = 2) AND ("c" = 3 OR "d" = 4)"#)
        #expect(prepared.splitted.query == #"SELECT "id" FROM "User" WHERE ("a" = $1 AND "b" = $2) AND ("c" = $3 OR "d" = $4)"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["1", "2", "3", "4"])
    }

    @Test("DQ05.3 empty dynamic WHERE omits the entire clause")
    func emptyWhereOmission() {
        let includeAge = false
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where {
                if includeAge {
                    Path.Column("age") >= 18
                }
            }
        }

        let prepared = query.prepare(.psql)
        #expect(prepared.plain == #"SELECT "id" FROM "User""#)
        #expect(prepared.splitted.query == #"SELECT "id" FROM "User""#)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("DQ05.3 empty dynamic predicates omit WHERE HAVING and QUALIFY")
    func emptyPredicateClauseOmission() {
        let includePredicate = false
        let ranked = Fn.rowNumber().over(partitionBy: Path.Column("group"), orderBy: .asc(Path.Column("id")))
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where {
                if includePredicate { Path.Column("age") >= 18 }
            }
            Having {
                if includePredicate { Fn.count(Path.Column("id")) > 1 }
            }
            Qualify {
                if includePredicate { ranked <= 3 }
            }
        }

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == #"SELECT "id" FROM "User""#)
        #expect(prepared.splitted.query == #"SELECT "id" FROM "User""#)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("DQ05.3 predicate expressions are snapshotted once when the request forms")
    func predicateSnapshot() {
        let probe = ClausePredicatePartsProbe()
        let query = SwifQL {
            Select { Path.Column("id") }
            Where { probe }
        }

        #expect(probe.partsReadCount == 1)
        _ = query.prepare(.psql)
        #expect(probe.partsReadCount == 1)
    }

    @Test("DQ05.3 HAVING without GROUP BY follows WHERE and binds in order")
    func havingWithoutGroupBy() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("active") == true }
            Having {
                Fn.count(Path.Column("id")) > 1
                Path.Column("maxAge") < 100
            }
        }

        let psql = query.prepare(.psql)
        #expect(psql.plain == #"SELECT "id" FROM "User" WHERE "active" = TRUE HAVING count("id") > 1 AND "maxAge" < 100"#)
        #expect(psql.splitted.query == #"SELECT "id" FROM "User" WHERE "active" = TRUE HAVING count("id") > $1 AND "maxAge" < $2"#)
        #expect(psql.splitted.values.map { String(describing: $0) } == ["1", "100"])

        let mysql = query.prepare(.mysql)
        #expect(mysql.plain == "SELECT id FROM User WHERE active = TRUE HAVING count(id) > 1 AND maxAge < 100")
        #expect(mysql.splitted.query == "SELECT id FROM User WHERE active = TRUE HAVING count(id) > ? AND maxAge < ?")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["1", "100"])
    }

    @Test("DQ05.3 QUALIFY uses the existing window expression and binds its predicate")
    func qualifyWindowExpression() {
        let ranked = Fn.rowNumber()
            .over(partitionBy: Path.Column("category"), orderBy: .asc(Path.Column("id")))
        let query = SwifQL {
            Select { ranked }
            From { Path.Table("events") }
            Qualify { ranked <= 3 }
        }

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == #"SELECT row_number() OVER (PARTITION BY "category" ORDER BY "id" ASC) FROM "events" QUALIFY row_number() OVER (PARTITION BY "category" ORDER BY "id" ASC) <= 3"#)
        #expect(prepared.splitted.query == #"SELECT row_number() OVER (PARTITION BY "category" ORDER BY "id" ASC) FROM "events" QUALIFY row_number() OVER (PARTITION BY "category" ORDER BY "id" ASC) <= $1"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["3"])
    }

    @Test("DQ05.3 nested FROM SELECT accepts WHERE HAVING QUALIFY then As")
    func nestedClauseSequence() {
        let ranked = Fn.rowNumber()
            .over(partitionBy: Path.Column("category"), orderBy: .asc(Path.Column("id")))
        let query = From {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            Having { Fn.count(Path.Column("id")) > 1 }
            Qualify { ranked <= 3 }
            As("filtered")
        }

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == #"FROM (SELECT "id" FROM "User" WHERE "age" >= 18 HAVING count("id") > 1 QUALIFY row_number() OVER (PARTITION BY "category" ORDER BY "id" ASC) <= 3) AS "filtered""#)
        #expect(prepared.splitted.query == #"FROM (SELECT "id" FROM "User" WHERE "age" >= $1 HAVING count("id") > $2 QUALIFY row_number() OVER (PARTITION BY "category" ORDER BY "id" ASC) <= $3) AS "filtered""#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["18", "1", "3"])
    }

    @Test("DQ05.3 WHERE remains attached after sibling JOIN")
    func whereAfterSiblingJoin() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Join(.left, Path.Table("Profile"))
            On(Path.Column("id") == Path.Column("userId"))
            Where { Path.Column("active") == true }
        }

        let prepared = query.prepare(.psql)
        #expect(prepared.plain == #"SELECT "id" FROM "User" LEFT JOIN "Profile" ON "id" = "userId" WHERE "active" = TRUE"#)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("DQ05.4 complete root clause chain preserves SQL and bind order")
    func completeGroupOrderLimitOffsetChain() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            GroupBy {
                Path.Column("id")
                Rollup(Path.Column("role"))
            }
            Having { Fn.count(Path.Column("id")) > 1 }
            OrderBy { OrderByItem.desc(Path.Column("id")) }
            Limit(10)
            Offset(2)
        }

        let psql = query.prepare(.psql)
        #expect(psql.plain == #"SELECT "id" FROM "User" WHERE "age" >= 18 GROUP BY "id", ROLLUP("role") HAVING count("id") > 1 ORDER BY "id" DESC LIMIT 10 OFFSET 2"#)
        #expect(psql.splitted.query == #"SELECT "id" FROM "User" WHERE "age" >= $1 GROUP BY "id", ROLLUP("role") HAVING count("id") > $2 ORDER BY "id" DESC LIMIT $3 OFFSET $4"#)
        #expect(psql.splitted.values.map { String(describing: $0) } == ["18", "1", "10", "2"])
        let root = query.parts.first as? SwifQLStructuralFramePart
        let groupBy = root?.children.compactMap { $0 as? SwifQLGroupByPart }.first
        let orderBy = root?.children.compactMap { $0 as? SwifQLOrderByPart }.first
        #expect(groupBy?.owner == query.structuralOwner(for: .groupBy))
        #expect(orderBy?.owner == query.structuralOwner(for: .orderBy))

        let mysql = query.prepare(.mysql)
        #expect(mysql.plain == "SELECT id FROM User WHERE age >= 18 GROUP BY id, ROLLUP(role) HAVING count(id) > 1 ORDER BY id DESC LIMIT 10 OFFSET 2")
        #expect(mysql.splitted.query == "SELECT id FROM User WHERE age >= ? GROUP BY id, ROLLUP(role) HAVING count(id) > ? ORDER BY id DESC LIMIT ? OFFSET ?")
        #expect(mysql.splitted.values.map { String(describing: $0) } == ["18", "1", "10", "2"])

        let duck = query.prepare(.duck)
        #expect(duck.plain == #"SELECT "id" FROM "User" WHERE "age" >= 18 GROUP BY "id", ROLLUP("role") HAVING count("id") > 1 ORDER BY "id" DESC LIMIT 10 OFFSET 2"#)
        #expect(duck.splitted.query == #"SELECT "id" FROM "User" WHERE "age" >= $1 GROUP BY "id", ROLLUP("role") HAVING count("id") > $2 ORDER BY "id" DESC LIMIT $3 OFFSET $4"#)
        #expect(duck.splitted.values.map { String(describing: $0) } == ["18", "1", "10", "2"])
    }

    @Test("DQ05.4 GROUP BY accepts existing ROLLUP CUBE and GROUPING SETS values")
    func existingGroupingForms() {
        let query = SwifQL {
            Select { Path.Column("id") }
            GroupBy {
                Path.Column("region")
                Rollup(Path.Column("role"))
                Cube(Path.Column("department"))
                GroupingSets([
                    [Path.Column("region")],
                    [Path.Column("role"), Path.Column("department")]
                ])
            }
        }

        #expect(query.prepare(.psql).plain == #"SELECT "id" GROUP BY "region", ROLLUP("role"), CUBE("department"), GROUPING SETS (("region"), ("role", "department"))"#)
        #expect(query.prepare(.mysql).plain == "SELECT id GROUP BY region, ROLLUP(role), CUBE(department), GROUPING SETS ((region), (role, department))")
        #expect(query.prepare(.duck).plain == #"SELECT "id" GROUP BY "region", ROLLUP("role"), CUBE("department"), GROUPING SETS (("region"), ("role", "department"))"#)
    }

    @Test("DQ05.4 empty dynamic GROUP BY and ORDER BY omit both clauses")
    func emptyGroupAndOrderOmission() {
        let includeGroup = false
        let includeOrder = false
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            GroupBy {
                if includeGroup { Path.Column("region") }
            }
            OrderBy {
                if includeOrder { OrderByItem.desc(Path.Column("id")) }
            }
            Limit(SwifQLableParts(rawParts: []))
            Offset(SwifQLableParts(rawParts: []))
        }

        let prepared = query.prepare(.psql)
        #expect(prepared.plain == #"SELECT "id" FROM "User""#)
        #expect(prepared.splitted.query == #"SELECT "id" FROM "User""#)
        #expect(prepared.splitted.values.isEmpty)
    }

    @Test("DQ05.4 builder and concise ORDER BY preserve the same query and binds")
    func builderAndConciseOrderByEquivalence() {
        let builderQuery = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            OrderBy { OrderByItem.desc(Path.Column("id")) }
            Limit(10)
            Offset(2)
        }
        let conciseQuery = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            OrderBy(Path.Column("id"), .desc)
            Limit(10)
            Offset(2)
        }

        let builder = builderQuery.prepare(.psql)
        let concise = conciseQuery.prepare(.psql)
        #expect(builder.plain == #"SELECT "id" FROM "User" WHERE "age" >= 18 ORDER BY "id" DESC LIMIT 10 OFFSET 2"#)
        #expect(builder.splitted.query == #"SELECT "id" FROM "User" WHERE "age" >= $1 ORDER BY "id" DESC LIMIT $2 OFFSET $3"#)
        #expect(builder.plain == concise.plain)
        #expect(builder.splitted.query == concise.splitted.query)
        #expect(builder.splitted.values.map { String(describing: $0) } == ["18", "10", "2"])
        #expect(concise.splitted.values.map { String(describing: $0) } == builder.splitted.values.map { String(describing: $0) })

        let nullOrdered = SwifQL {
            Select { Path.Column("id") }
            OrderBy { OrderByItem.asc(Path.Column("id"), nulls: .last) }
        }
        #expect(nullOrdered.prepare(.psql).plain == #"SELECT "id" ORDER BY "id" ASC NULLS LAST"#)
    }

    @Test("DQ05.4 nested SELECT accepts clauses before As and keeps bind order")
    func nestedGroupOrderLimitOffsetAndAlias() {
        let ranked = Fn.rowNumber().over(partitionBy: Path.Column("role"), orderBy: .asc(Path.Column("id")))
        let query = From {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            GroupBy {
                Path.Column("id")
                Rollup(Path.Column("role"))
            }
            Having { Fn.count(Path.Column("id")) > 1 }
            Qualify { ranked <= 3 }
            OrderBy { OrderByItem.desc(Path.Column("id")) }
            Limit(10)
            Offset(2)
            As("filtered")
        }

        let prepared = query.prepare(.duck)
        #expect(prepared.plain == #"FROM (SELECT "id" FROM "User" WHERE "age" >= 18 GROUP BY "id", ROLLUP("role") HAVING count("id") > 1 QUALIFY row_number() OVER (PARTITION BY "role" ORDER BY "id" ASC) <= 3 ORDER BY "id" DESC LIMIT 10 OFFSET 2) AS "filtered""#)
        #expect(prepared.splitted.query == #"FROM (SELECT "id" FROM "User" WHERE "age" >= $1 GROUP BY "id", ROLLUP("role") HAVING count("id") > $2 QUALIFY row_number() OVER (PARTITION BY "role" ORDER BY "id" ASC) <= $3 ORDER BY "id" DESC LIMIT $4 OFFSET $5) AS "filtered""#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["18", "1", "3", "10", "2"])
    }

    @Test("DQ05.4 nested SELECT can start GROUP and result-order clauses before As")
    func nestedSelectClausesWithoutNestedFrom() {
        let query = From {
            Select { Path.Column("id") }
            GroupBy { Path.Column("id") }
            OrderBy { OrderByItem.desc(Path.Column("id")) }
            Limit(10)
            Offset(2)
            As("direct")
        }

        let prepared = query.prepare(.psql)
        #expect(prepared.plain == #"FROM (SELECT "id" GROUP BY "id" ORDER BY "id" DESC LIMIT 10 OFFSET 2) AS "direct""#)
        #expect(prepared.splitted.query == #"FROM (SELECT "id" GROUP BY "id" ORDER BY "id" DESC LIMIT $1 OFFSET $2) AS "direct""#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["10", "2"])
    }

    @Test("DQ05.4 GROUP and ORDER remain attached after sibling JOIN")
    func groupOrderAfterSiblingJoin() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Join(.left, Path.Table("Profile"))
            On(Path.Column("id") == Path.Column("userId"))
            Where { Path.Column("active") == true }
            GroupBy { Path.Column("role") }
            OrderBy(Path.Column("id"), .desc)
        }

        let prepared = query.prepare(.psql)
        #expect(prepared.plain == #"SELECT "id" FROM "User" LEFT JOIN "Profile" ON "id" = "userId" WHERE "active" = TRUE GROUP BY "role" ORDER BY "id" DESC"#)
        #expect(prepared.splitted.values.isEmpty)
    }
}
