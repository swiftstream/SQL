import Foundation
import Testing
@testable import SQL

private struct ConciseParityUser: Table {
    static var tableName: String { "users" }

    @Column("id")
    var id: Int
    @Column("email")
    var email: String
    @Column("active")
    var active: Bool
    @Column("role")
    var role: String

    init() {}
}

private struct ConciseParityProfile: Table {
    static var tableName: String { "profiles" }

    @Column("id")
    var id: Int
    @Column("user_id")
    var userID: Int

    init() {}
}

private final class ConciseParityPartsProbe: SQLable {
    private let payload: [SQLPart]
    private(set) var partsReadCount = 0

    init(_ payload: [SQLPart]) {
        self.payload = payload
    }

    var parts: [SQLPart] {
        partsReadCount += 1
        return payload
    }
}

@Suite("Declarative concise parity")
struct DeclarativeQueryConciseParityTests {
    private typealias User = ConciseParityUser
    private typealias Profile = ConciseParityProfile

    private func expectEquivalent(
        _ concise: any SQLable,
        _ builder: any SQLable
    ) {
        for dialect in SQLDialect.all {
            let concisePrepared = concise.prepare(dialect)
            let builderPrepared = builder.prepare(dialect)

            #expect(concisePrepared.plain == builderPrepared.plain)
            #expect(concisePrepared.splitted.query == builderPrepared.splitted.query)
            #expect(
                concisePrepared.splitted.values.map { String(describing: $0) }
                    == builderPrepared.splitted.values.map { String(describing: $0) }
            )
        }
    }

    @Test("C01 concise From one source matches builder form")
    func c01ConciseFromOneSource() {
        let concise = SQL {
            Select(\User.$id)
            From(User.table)
        }
        let builder = SQL {
            Select(\User.$id)
            From {
                User.table
            }
        }

        expectEquivalent(concise, builder)
    }

    @Test("C02 concise From multiple sources preserves comma order")
    func c02ConciseFromMultipleSources() {
        let concise = SQL {
            Select(\User.$id)
            From(User.table, Profile.table)
        }
        let builder = SQL {
            Select(\User.$id)
            From {
                User.table
                Profile.table
            }
        }

        expectEquivalent(concise, builder)
        #expect(
            concise.prepare(.psql).plain
                == #"SELECT "users"."id" FROM "users", "profiles""#
        )
    }

    @Test("C03 concise From preserves aliased nested statement embedding and binds")
    func c03ConciseFromNestedStatement() {
        let nested = SQL {
            Select(\User.$id)
            From(User.table)
            Where(\User.$email == "nested@example.com")
        }
        .as("filtered")

        let concise = From(nested)
        let builder = From {
            nested
        }

        expectEquivalent(concise, builder)

        let postgres = concise.prepare(.psql)
        #expect(
            postgres.splitted.query
                == #"FROM (SELECT "users"."id" FROM "users" WHERE "users"."email" = $1) as "filtered""#
        )
        #expect(
            postgres.splitted.values.map { String(describing: $0) }
                == ["nested@example.com"]
        )
    }

    @Test("C04 concise From snapshots each source exactly once")
    func c04ConciseFromOneEvaluation() {
        let probe = ConciseParityPartsProbe(User.table.parts)
        let concise = From(probe)

        #expect(probe.partsReadCount == 1)
        _ = concise.prepare(.psql)
        _ = concise.prepare(.mysql)
        _ = concise.prepare(.duck)
        #expect(probe.partsReadCount == 1)
    }

    @Test("C05 concise Where matches builder form with explicit boolean expression")
    func c05ConciseWhereParity() {
        let predicate = \User.$email == "a@a.com" && \User.$active == true

        let concise = SQL {
            Select(\User.$id)
            From(User.table)
            Where(predicate)
        }
        let builder = SQL {
            Select(\User.$id)
            From(User.table)
            Where {
                predicate
            }
        }

        expectEquivalent(concise, builder)
    }

    @Test("C06 concise Where remains valid inside nested From composition")
    func c06NestedConciseWhere() {
        let concise = From {
            Select {
                \User.$id
            }
            From(User.table)
            Where(\User.$email == "nested@example.com")
            As("filtered")
        }
        let builder = From {
            Select {
                \User.$id
            }
            From(User.table)
            Where {
                \User.$email == "nested@example.com"
            }
            As("filtered")
        }

        expectEquivalent(concise, builder)
    }

    @Test("C07 concise Having matches builder form")
    func c07ConciseHavingParity() {
        let predicate = Fn.count(\User.$id) > 1

        let concise = SQL {
            Select(\User.$role)
            From(User.table)
            GroupBy(\User.$role)
            Having(predicate)
        }
        let builder = SQL {
            Select(\User.$role)
            From(User.table)
            GroupBy(\User.$role)
            Having {
                predicate
            }
        }

        expectEquivalent(concise, builder)
    }

    @Test("C08 concise Qualify matches builder form")
    func c08ConciseQualifyParity() {
        let ranked = Fn.rowNumber()
            .over(partitionBy: \User.$role, orderBy: .asc(\User.$id))
        let predicate = ranked <= 3

        let concise = SQL {
            Select(\User.$id)
            From(User.table)
            Qualify(predicate)
        }
        let builder = SQL {
            Select(\User.$id)
            From(User.table)
            Qualify {
                predicate
            }
        }

        expectEquivalent(concise, builder)
    }

    @Test("C09 concise predicate requests snapshot parts exactly once")
    func c09PredicateOneEvaluation() {
        let trueParts = SQLBool(true).parts
        let whereProbe = ConciseParityPartsProbe(trueParts)
        let havingProbe = ConciseParityPartsProbe(trueParts)
        let qualifyProbe = ConciseParityPartsProbe(trueParts)

        let whereClause = Where(whereProbe)
        let havingClause = Having(havingProbe)
        let qualifyClause = Qualify(qualifyProbe)

        #expect(whereProbe.partsReadCount == 1)
        #expect(havingProbe.partsReadCount == 1)
        #expect(qualifyProbe.partsReadCount == 1)

        _ = whereClause.prepare(.psql)
        _ = havingClause.prepare(.psql)
        _ = qualifyClause.prepare(.duck)

        #expect(whereProbe.partsReadCount == 1)
        #expect(havingProbe.partsReadCount == 1)
        #expect(qualifyProbe.partsReadCount == 1)
    }

    @Test("C10 concise GroupBy matches builder form for advanced grouping values")
    func c10ConciseGroupByParity() {
        let role: any SQLable = \User.$role
        let active: any SQLable = \User.$active
        let groupingSets = GroupingSets([
            [role],
            [active]
        ])

        let concise = SQL {
            Select(\User.$role)
            From(User.table)
            GroupBy(
                \User.$role,
                Rollup(\User.$id),
                Cube(\User.$active),
                groupingSets
            )
        }
        let builder = SQL {
            Select(\User.$role)
            From(User.table)
            GroupBy {
                \User.$role
                Rollup(\User.$id)
                Cube(\User.$active)
                groupingSets
            }
        }

        expectEquivalent(concise, builder)
    }

    @Test("C11 concise GroupBy omits empty children like the builder")
    func c11ConciseGroupByEmptyChild() {
        let empty = SQLableParts(rawParts: [])

        let concise = SQL {
            Select(\User.$role)
            From(User.table)
            GroupBy(\User.$role, empty, \User.$active)
        }
        let builder = SQL {
            Select(\User.$role)
            From(User.table)
            GroupBy {
                \User.$role
                empty
                \User.$active
            }
        }

        expectEquivalent(concise, builder)
        #expect(
            concise.prepare(.psql).plain
                == #"SELECT "users"."role" FROM "users" GROUP BY "users"."role", "users"."active""#
        )
    }

    @Test("C12 concise OrderBy items match builder form")
    func c12ConciseOrderByItems() {
        let concise = SQL {
            Select(\User.$id, \User.$email)
            From(User.table)
            OrderBy(
                .asc(\User.$email, nulls: .last),
                .desc(\User.$id)
            )
        }
        let builder = SQL {
            Select(\User.$id, \User.$email)
            From(User.table)
            OrderBy {
                OrderByItem.asc(\User.$email, nulls: .last)
                OrderByItem.desc(\User.$id)
            }
        }

        expectEquivalent(concise, builder)
    }

    @Test("C13 existing OrderBy expression-direction overload remains unchanged")
    func c13ExistingOrderByExpressionDirection() {
        let query = SQL {
            Select(\User.$id)
            From(User.table)
            OrderBy(\User.$email, .desc)
        }

        #expect(
            query.prepare(.psql).plain
                == #"SELECT "users"."id" FROM "users" ORDER BY "users"."email" DESC"#
        )
    }

    @Test("C14 complete concise root preserves exact SQL and bind order")
    func c14CompleteConciseRoot() {
        let concise = SQL {
            Select(\User.$id, \User.$email)
            From(User.table)
            Where(\User.$email == "a@a.com" && \User.$active == true)
            GroupBy(\User.$id, \User.$email)
            Having(Fn.count(\User.$id) > 0)
            OrderBy(.asc(\User.$email), .desc(\User.$id))
            Limit(20)
            Offset(0)
        }

        let builder = SQL {
            Select {
                \User.$id
                \User.$email
            }
            From {
                User.table
            }
            Where {
                \User.$email == "a@a.com" && \User.$active == true
            }
            GroupBy {
                \User.$id
                \User.$email
            }
            Having {
                Fn.count(\User.$id) > 0
            }
            OrderBy {
                OrderByItem.asc(\User.$email)
                OrderByItem.desc(\User.$id)
            }
            Limit(20)
            Offset(0)
        }

        expectEquivalent(concise, builder)

        let psql = concise.prepare(.psql)
        #expect(
            psql.plain
                == #"SELECT "users"."id", "users"."email" FROM "users" WHERE "users"."email" = 'a@a.com' AND "users"."active" = TRUE GROUP BY "users"."id", "users"."email" HAVING count("users"."id") > 0 ORDER BY "users"."email" ASC, "users"."id" DESC LIMIT 20 OFFSET 0"#
        )
        #expect(
            psql.splitted.query
                == #"SELECT "users"."id", "users"."email" FROM "users" WHERE "users"."email" = $1 AND "users"."active" = TRUE GROUP BY "users"."id", "users"."email" HAVING count("users"."id") > $2 ORDER BY "users"."email" ASC, "users"."id" DESC LIMIT $3 OFFSET $4"#
        )
        #expect(
            psql.splitted.values.map { String(describing: $0) }
                == ["a@a.com", "0", "20", "0"]
        )
    }

    @Test("C15 builder-heavy control flow remains equivalent to concise fixed fragments")
    func c15BuilderRegression() {
        let includeEmail = true
        let roles = ["admin", "editor"]

        let builder = SQL {
            Select {
                \User.$id
                \User.$email
            }
            From {
                User.table
            }
            Where {
                \User.$active == true

                if includeEmail {
                    \User.$email == "a@a.com"
                }

                Or {
                    for role in roles {
                        \User.$role == role
                    }
                }
            }
            OrderBy {
                OrderByItem.asc(\User.$email)
            }
        }

        let psql = builder.prepare(.psql)
        #expect(
            psql.plain
                == #"SELECT "users"."id", "users"."email" FROM "users" WHERE "users"."active" = TRUE AND "users"."email" = 'a@a.com' AND ("users"."role" = 'admin' OR "users"."role" = 'editor') ORDER BY "users"."email" ASC"#
        )
        #expect(
            psql.splitted.query
                == #"SELECT "users"."id", "users"."email" FROM "users" WHERE "users"."active" = TRUE AND "users"."email" = $1 AND ("users"."role" = $2 OR "users"."role" = $3) ORDER BY "users"."email" ASC"#
        )
        #expect(
            psql.splitted.values.map { String(describing: $0) }
                == ["a@a.com", "admin", "editor"]
        )
    }
}
