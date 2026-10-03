import Testing
import SwifQL

@Suite("DESIGN-037 former compiler negatives as normal positive tests")
struct Design037FormerNegativePositiveTests {
    @Test("standalone JOIN, ON, USING, alias, and DEFAULT fragments render")
    func standaloneContinuationFragments() {
        let join = SwifQL { Join(.left, Path.Table("Profile")); On(true) }
        let using = SwifQL { Using("id") }
        let alias = SwifQL { As("alias") }
        let defaultValue = SwifQL { Default() }
        #expect(join.prepare(.psql).plain == #"LEFT JOIN "Profile" ON TRUE"#)
        #expect(using.prepare(.psql).plain == #"USING ("id")"#)
        #expect(alias.prepare(.psql).plain == #"AS "alias""#)
        #expect(defaultValue.prepare(.psql).plain == "DEFAULT")
    }

    @Test("N01 orphan SELECT alias renders as a fragment")
    func n01() {
        let query = Select { As("identifier") }
        #expect(query.prepare(.psql).plain == #"SELECT as "identifier""#)
    }

    @Test("N02 late DISTINCT stays in SELECT source order")
    func n02() {
        let query = Select {
            Path.Column("id")
            Distinct()
        }
        #expect(query.prepare(.psql).plain == #"SELECT "id", DISTINCT"#)
    }

    @Test("N03 conditional complete DISTINCT projection branch")
    func n03() {
        let flag = true
        let query = Select {
            if flag {
                Distinct()
                Path.Column("id")
            }
            Path.Column("email")
        }
        #expect(query.prepare(.psql).plain == #"SELECT DISTINCT "id", "email""#)
    }

    @Test("N04 late conditional SELECT modifier remains in source order")
    func n04() {
        let flag = true
        let query = Select {
            Path.Column("id")
            if flag {
                Distinct()
                Path.Column("email")
            }
        }
        #expect(query.prepare(.psql).plain == #"SELECT "id", DISTINCT, "email""#)
    }

    @Test("N05 mixed DISTINCT modifiers remain representable")
    func n05() {
        let flag = true
        let query = Select {
            Distinct()
            if flag {
                DistinctOn(Path.Column("country"))
                Path.Column("id")
            }
        }
        #expect(query.prepare(.psql).plain == #"SELECT DISTINCT DISTINCT ON ("country") "id""#)
    }

    @Test("N06 if else can choose either complete projection branch")
    func n06() {
        let flag = true
        let selected = Select {
            if flag {
                Distinct()
                Path.Column("id")
            } else {
                Path.Column("email")
            }
            Path.Column("name")
        }
        let plain = Select {
            if !flag {
                Distinct()
                Path.Column("id")
            } else {
                Path.Column("email")
            }
            Path.Column("name")
        }
        #expect(selected.prepare(.psql).plain == #"SELECT DISTINCT "id", "name""#)
        #expect(plain.prepare(.psql).plain == #"SELECT "email", "name""#)
    }

    @Test("N07 loop bodies can produce modifier and projection groups")
    func n07() {
        let values = [1]
        let query = Select {
            for _ in values {
                Distinct()
                Path.Column("id")
            }
        }
        let fields = [Path.Column("id"), Path.Column("email")]
        let projections = Select {
            for field in fields { field }
        }
        #expect(query.prepare(.psql).plain == #"SELECT DISTINCT "id""#)
        #expect(projections.prepare(.psql).plain == #"SELECT "id", "email""#)
    }

    @Test("N08 FROM column list does not require an alias")
    func n08() {
        let query = From {
            Path.Table("User")
            Columns("id")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" ("id")"#)
    }

    @Test("N09 WITH ORDINALITY can follow a source alias")
    func n09() {
        let query = From {
            Fn.generateSeries(1, 2)
            As("series")
            WithOrdinality()
        }
        #expect(query.prepare(.psql).plain == #"FROM generate_series(1, 2) AS "series" WITH ORDINALITY"#)
    }

    @Test("N10 nested FROM then SELECT renders in source order")
    func n10() {
        let query = From {
            From { Path.Table("User") }
            Select { Path.Column("id") }
        }
        #expect(query.prepare(.psql).plain == #"FROM (FROM "User"), (SELECT "id")"#)
    }

    @Test("N11 orphan JOIN and ON can render inside FROM")
    func n11() {
        let query = From {
            Join(.left, Path.Table("Profile"))
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM LEFT JOIN "Profile" ON TRUE"#)
    }

    @Test("N12 a source may follow a FROM JOIN continuation")
    func n12() {
        let query = From {
            Join(.left, Path.Table("Profile"))
            On(true)
            Path.Table("User")
        }
        #expect(query.prepare(.psql).plain == #"FROM LEFT JOIN "Profile" ON TRUE, "User""#)
    }

    @Test("N13 standalone root JOIN fragment composes with ON")
    func n13() {
        let query = SwifQL {
            Join(.left, Path.Table("Profile"))
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"LEFT JOIN "Profile" ON TRUE"#)
    }

    @Test("N14 erased FROM and sibling JOIN compose directly")
    func n14() {
        let erased: any SwifQLable = From { Path.Table("User") }
        let query = SwifQL {
            erased
            Join(.left, Path.Table("Profile"))
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" ON TRUE"#)
    }

    @Test("N15 maybe empty FROM and sibling JOIN remain composable")
    func n15() {
        let populated: FromBuilder.Result = From {
            if true { Path.Table("User") }
        }
        let empty: FromBuilder.Result = From {
            if false { Path.Table("User") }
        }
        let populatedQuery = SwifQL {
            populated
            Join(.left, Path.Table("Profile"))
            On(true)
        }
        let emptyQuery = SwifQL {
            empty
            Join(.left, Path.Table("Profile"))
            On(true)
        }
        #expect(populatedQuery.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" ON TRUE"#)
        #expect(emptyQuery.prepare(.psql).plain == #"FROM LEFT JOIN "Profile" ON TRUE"#)
    }

    @Test("N16 JOIN may follow a root control-flow group")
    func n16() {
        let query = SwifQL {
            if true { From { Path.Table("User") } }
            Join(.left, Path.Table("Profile"))
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" ON TRUE"#)
    }

    @Test("N17 root ON remains independently composable")
    func n17() {
        let query = SwifQL {
            From { Path.Table("User") }
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" ON TRUE"#)
    }

    @Test("N18 root USING remains independently composable")
    func n18() {
        let query = SwifQL {
            From { Path.Table("User") }
            Using("id")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" USING ("id")"#)
    }

    @Test("N19 root WHERE fragment renders alone")
    func n19() {
        let query = SwifQL { Where { Path.Column("id") > 0 } }
        #expect(query.prepare(.psql).plain == #"WHERE "id" > 0"#)
    }

    @Test("N20 root GROUP BY fragment renders alone")
    func n20() {
        let query = SwifQL { GroupBy { Path.Column("id") } }
        #expect(query.prepare(.psql).plain == #"GROUP BY "id""#)
    }

    @Test("N21 root HAVING fragment renders alone")
    func n21() {
        let query = SwifQL { Having { Fn.count(Path.Column("id")) > 1 } }
        #expect(query.prepare(.psql).plain == #"HAVING count("id") > 1"#)
    }

    @Test("N22 root QUALIFY fragment renders alone")
    func n22() {
        let query = SwifQL { Qualify { Path.Column("id") > 0 } }
        #expect(query.prepare(.psql).plain == #"QUALIFY "id" > 0"#)
    }

    @Test("N23 root ORDER BY fragment renders alone")
    func n23() {
        let query = SwifQL { OrderBy { OrderByItem.desc(Path.Column("id")) } }
        #expect(query.prepare(.psql).plain == #"ORDER BY "id" DESC"#)
    }

    @Test("N24 root LIMIT fragment renders alone")
    func n24() {
        let query = SwifQL { Limit(1) }
        #expect(query.prepare(.psql).plain == "LIMIT 1")
    }

    @Test("N25 root OFFSET fragment renders alone")
    func n25() {
        let query = SwifQL { Offset(1) }
        #expect(query.prepare(.psql).plain == "OFFSET 1")
    }

    @Test("N26 WHERE may follow HAVING in root source order")
    func n26() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Having { Fn.count(Path.Column("id")) > 1 }
            Where { Path.Column("id") > 0 }
        }
        #expect(query.prepare(.psql).plain == #"SELECT "id" FROM "User" HAVING count("id") > 1 WHERE "id" > 0"#)
    }

    @Test("N27 HAVING may follow QUALIFY in root source order")
    func n27() {
        let query = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Qualify { Path.Column("id") > 0 }
            Having { Fn.count(Path.Column("id")) > 1 }
        }
        #expect(query.prepare(.psql).plain == #"SELECT "id" FROM "User" QUALIFY "id" > 0 HAVING count("id") > 1"#)
    }

    @Test("N28 a clause may follow a finalized root group")
    func n28() {
        let query = SwifQL {
            if true {
                Select { Path.Column("id") }
                From { Path.Table("User") }
            }
            Where { Path.Column("id") > 0 }
        }
        #expect(query.prepare(.psql).plain == #"SELECT "id" FROM "User" WHERE "id" > 0"#)
    }

    @Test("N29 DEFAULT is an ordinary SwifQLable fragment")
    func n29() {
        let value: any SwifQLable = Default()
        #expect(value.prepare(.psql).plain == "DEFAULT")
    }

    @Test("N30 SELECT DEFAULT composes without statement validation")
    func n30() {
        let query = Select { Default() }
        #expect(query.prepare(.psql).plain == "SELECT DEFAULT")
    }

    @Test("N31 INSERT VALUES may precede target columns")
    func n31() {
        let query = Insert(Path.Table("User")) {
            Values { Row(1) }
            Columns { "id" }
        }
        #expect(query.prepare(.psql).plain == #"INSERT INTO "User" VALUES (1) ("id")"#)
    }

    @Test("N32 INSERT may omit an explicit column list")
    func n32() {
        let query = Insert(Path.Table("User")) {
            Values { Row(1) }
        }
        #expect(query.prepare(.psql).plain == #"INSERT INTO "User" VALUES (1)"#)
    }

    @Test("N33 incomplete INSERT body remains a fragment")
    func n33() {
        let query = Insert(Path.Table("User")) {
            Columns { "id" }
        }
        #expect(query.prepare(.psql).plain == #"INSERT INTO "User" ("id")"#)
    }

    @Test("P01-P14 prior positive source concepts still compile and render")
    func p01ThroughP14() {
        let p01 = Select { Path.Column("id"); As("identifier") }
        let p02 = Select { if true { Distinct() }; Path.Column("id") }
        let p03 = From { Path.Table("User"); As("u"); Columns("id", "name") }
        let p04 = From {
            Fn.generateSeries(1, 2)
            WithOrdinality()
            As("series")
            Columns("value", "position")
        }
        let p05 = From {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            As("users")
        }
        let p06 = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile"))
            As("profile")
            On(true)
        }
        let p07 = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile"))
            Using("id")
            As("keys")
        }
        let p08Base = From { Path.Table("User") }
        let p08 = SwifQL { p08Base; Join(.left, Path.Table("Profile")); On(true) }
        let p09 = SwifQL { From { Path.Table("User") }; Select { Path.Column("id") } }
        let p10 = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            GroupBy { Path.Column("id") }
            Having { Fn.count(Path.Column("id")) > 1 }
            Qualify { Path.Column("id") > 0 }
            OrderBy { OrderByItem.desc(Path.Column("id")) }
            Limit(10)
            Offset(2)
        }
        let p11 = From {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("age") >= 18 }
            GroupBy { Path.Column("id") }
            Having { Fn.count(Path.Column("id")) > 1 }
            OrderBy { OrderByItem.desc(Path.Column("id")) }
            Limit(10)
            Offset(2)
            As("filtered")
        }
        let p12 = From {
            Path.Table("Organization")
            if true {
                Path.Table("User")
                As("u")
            }
        }
        let p13 = Insert(Path.Table("User")) {
            Columns { "id"; "name"; "createdAt" }
            Values {
                Row(1, "John", Default())
                Row(2, "Kate", Default())
            }
        }
        let p14 = From {
            Values { Row("admin", 100) }
            As("rp")
            Columns { "role"; "priority" }
        }
        let positives: [any SwifQLable] = [
            p01, p02, p03, p04, p05, p06, p07,
            p08, p09, p10, p11, p12, p13, p14
        ]
        #expect(positives.count == 14)
        #expect(positives.allSatisfy { !$0.prepare(.psql).plain.isEmpty })
        #expect(positives.map { $0.prepare(.psql).plain } == [
            #"SELECT "id" as "identifier""#,
            #"SELECT DISTINCT "id""#,
            #"FROM "User" AS "u" ("id", "name")"#,
            #"FROM generate_series(1, 2) WITH ORDINALITY AS "series" ("value", "position")"#,
            #"FROM (SELECT "id" FROM "User") AS "users""#,
            #"FROM "User" LEFT JOIN "Profile" AS "profile" ON TRUE"#,
            #"FROM "User" LEFT JOIN "Profile" USING ("id") AS "keys""#,
            #"FROM "User" LEFT JOIN "Profile" ON TRUE"#,
            #"FROM "User" SELECT "id""#,
            #"SELECT "id" FROM "User" WHERE "age" >= 18 GROUP BY "id" HAVING count("id") > 1 QUALIFY "id" > 0 ORDER BY "id" DESC LIMIT 10 OFFSET 2"#,
            #"FROM (SELECT "id" FROM "User" WHERE "age" >= 18 GROUP BY "id" HAVING count("id") > 1 ORDER BY "id" DESC LIMIT 10 OFFSET 2) AS "filtered""#,
            #"FROM "Organization", "User" AS "u""#,
            #"INSERT INTO "User" ("id", "name", "createdAt") VALUES (1, 'John', DEFAULT), (2, 'Kate', DEFAULT)"#,
            #"FROM (VALUES ('admin', 100)) AS "rp" ("role", "priority")"#
        ])
    }

    @Test("canonical root preserves bind order across fragment boundaries")
    func canonicalBindingOrder() {
        let query = SwifQL {
            Select { "projection" }
            From { Path.Table("User") }
            Where { Path.Column("email") == "active@example.com" }
            Limit(10)
        }
        let prepared = query.prepare(.psql)
        #expect(prepared.splitted.query == #"SELECT $1 FROM "User" WHERE "email" = $2 LIMIT $3"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["projection", "active@example.com", "10"])
    }

    @Test("dynamic empty WHERE stays omitted at the fragment root")
    func dynamicEmptyWhere() {
        let query = SwifQL {
            Select { Path.Column("id") }
            Where { if false { Path.Column("id") > 0 } }
        }
        #expect(query.prepare(.psql).plain == #"SELECT "id""#)
    }
    @Test("FROM control flow keeps ordered source and JOIN identities")
    func fromControlFlowAndJoinOrdering() {
        let userOnly = From {
            if true { Path.Table("User") }
        }
        #expect(userOnly.prepare(.psql).plain == #"FROM "User""#)

        let emptyOnly = From {
            if false { }
        }
        #expect(emptyOnly.prepare(.psql).plain == "FROM ")

        let withOptionalThenJoin = From {
            Path.Table("User")
            if true { Path.Table("Profile") }
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(withOptionalThenJoin.prepare(.psql).plain == #"FROM "User", "Profile" LEFT JOIN "Account" ON TRUE"#)

        let withoutOptionalThenJoin = From {
            Path.Table("User")
            if false { Path.Table("Profile") }
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(withoutOptionalThenJoin.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Account" ON TRUE"#)

        let onlyOptionalJoinPresent = From {
            if true { Path.Table("Profile") }
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(onlyOptionalJoinPresent.prepare(.psql).plain == #"FROM "Profile" LEFT JOIN "Account" ON TRUE"#)

        let onlyOptionalJoinAbsent = From {
            if false { Path.Table("Profile") }
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(onlyOptionalJoinAbsent.prepare(.psql).plain == #"FROM LEFT JOIN "Account" ON TRUE"#)

        let tables = ["User", "Profile"]
        let loopThenSource = From {
            for table in tables { Path.Table(table) }
            Path.Table("Organization")
        }
        #expect(loopThenSource.prepare(.psql).plain == #"FROM "User", "Profile", "Organization""#)

        let loopThenJoin = From {
            for table in tables { Path.Table(table) }
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(loopThenJoin.prepare(.psql).plain == #"FROM "User", "Profile" LEFT JOIN "Account" ON TRUE"#)

        let valuesBranch = From {
            if true {
                Values { Row(1) }
            } else {
                Path.Table("User")
            }
            Path.Table("Organization")
        }
        #expect(valuesBranch.prepare(.psql).plain == #"FROM (VALUES (1)), "Organization""#)

        let tableBranchThenJoin = From {
            if true { Path.Table("User") } else { Path.Table("Profile") }
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(tableBranchThenJoin.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Account" ON TRUE"#)
    }

}
