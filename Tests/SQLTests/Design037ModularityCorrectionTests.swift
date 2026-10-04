import Foundation
import Testing
import SQL

private struct Design037ModularityUser: Table {
    static var tableName: String { "User" }

    @Column("id") var id: Int
    @Column("name") var name: String

    init() {}
}

private struct DualUsingInput: SwifQLable, KeyPathLastPath {
    var lastPath: String { "legacyName" }
    var parts: [SwifQLPart] { [SwifQLPartKeyPath(paths: "structuralName")] }
}

@Suite("DESIGN-037 modularity correction")
struct Design037ModularityCorrectionTests {
    private typealias User = Design037ModularityUser

    @Test("Stored statement aliases keep postfix suffixes outside the statement")
    func storedStatementAliases() {
        let statement = Select { Path.Column("id") }
        let fluent = statement.as("x")
        let operatorAlias = statement => "x"
        let expressionAlias = statement.as(=>"x")
        let chained = statement.as("x").as("y")

        #expect(fluent.prepare(.psql).plain == #"SELECT "id" as "x""#)
        #expect(operatorAlias.prepare(.psql).plain == fluent.prepare(.psql).plain)
        #expect(expressionAlias.prepare(.psql).plain == fluent.prepare(.psql).plain)
        #expect(chained.prepare(.psql).plain == #"SELECT "id" as "x" as "y""#)
        #expect(From { statement }.prepare(.psql).plain == #"FROM (SELECT "id")"#)
        #expect(From { fluent }.prepare(.psql).plain == #"FROM (SELECT "id") as "x""#)
        #expect(From { operatorAlias }.prepare(.psql).plain == #"FROM (SELECT "id") as "x""#)
        #expect(From { expressionAlias }.prepare(.psql).plain == #"FROM (SELECT "id") as "x""#)
        #expect(From { chained }.prepare(.psql).plain == #"FROM (SELECT "id") as "x" as "y""#)
    }

    @Test("Public set results embed atomically in FROM, SELECT, and value JOIN")
    func setResultEmbedding() {
        let left: any SwifQLable = Select { Path.Column("id") }
        let right: any SwifQLable = Select { Path.Column("name") }
        let setResult = Union([left, right])
        let aliasedSet = setResult.as("combined")

        #expect(setResult.prepare(.psql).plain == #"(SELECT "id") UNION (SELECT "name")"#)
        #expect(From { setResult }.prepare(.psql).plain == #"FROM ((SELECT "id") UNION (SELECT "name"))"#)
        #expect(From { aliasedSet }.prepare(.psql).plain == #"FROM ((SELECT "id") UNION (SELECT "name")) as "combined""#)
        #expect(Select { setResult }.prepare(.psql).plain == #"SELECT ((SELECT "id") UNION (SELECT "name"))"#)
        #expect(Select { aliasedSet }.prepare(.psql).plain == #"SELECT ((SELECT "id") UNION (SELECT "name")) as "combined""#)

        let joined = From {
            Path.Table("User")
            Join(.left, aliasedSet)
            On(true)
        }
        #expect(joined.prepare(.psql).plain == #"FROM "User" LEFT JOIN ((SELECT "id") UNION (SELECT "name")) as "combined" ON TRUE"#)
    }

    @Test("Value JOIN embeds statements and preserves the closure form")
    func statementJoinEmbedding() {
        let statement: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("Profile") }
        }
        let plain = From {
            Path.Table("User")
            Join(.left, statement)
            On(true)
        }
        let aliased = From {
            Path.Table("User")
            Join(.left, statement.as("profile"))
            On(true)
        }
        let closure = From {
            Path.Table("User")
            Join(.left) {
                Select { Path.Column("id") }
                From { Path.Table("Profile") }
            }
            On(true)
        }

        #expect(plain.prepare(.psql).plain == #"FROM "User" LEFT JOIN (SELECT "id" FROM "Profile") ON TRUE"#)
        #expect(aliased.prepare(.psql).plain == #"FROM "User" LEFT JOIN (SELECT "id" FROM "Profile") as "profile" ON TRUE"#)
        #expect(closure.prepare(.psql).plain == plain.prepare(.psql).plain)
        #expect(From { Join(.inner, Path.Table("Profile")) }.prepare(.psql).plain == #"FROM INNER JOIN "Profile""#)
    }

    @Test("Stored statements remain one scalar SELECT projection")
    func statementProjectionEmbedding() {
        let statement: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("User") }
            Where { Path.Column("id") == "inside" }
        }
        let aliased = statement.as("one")

        #expect(
            Select { statement; Path.Column("name") }.prepare(.psql).plain
                == #"SELECT (SELECT "id" FROM "User" WHERE "id" = 'inside'), "name""#
        )
        #expect(
            Select { aliased; Path.Column("name") }.prepare(.psql).plain
                == #"SELECT (SELECT "id" FROM "User" WHERE "id" = 'inside') as "one", "name""#
        )
        #expect(
            Select { Path.Column("id").as("identifier"); Path.Column("name") => "displayName" }
                .prepare(.psql).plain == #"SELECT "id" as "identifier", "name" as "displayName""#
        )
    }

    @Test("Nested source, JOIN, and projection keep bind order across dialects")
    func nestedBindOrderAndDialects() {
        let nested: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            From { Path.Table("Inner") }
            Where { Path.Column("id") == "inside" }
        }
        let source = From { nested.as("q"); Fn.generateSeries("tail", "end") }
        let join = From {
            Path.Table("Outer")
            Join(.inner, nested.as("q"))
            On(Path.Column("enabled") == "yes")
        }
        let projection = Select { nested; "outside" }

        let sourceSplit = source.prepare(.psql).splitted
        #expect(sourceSplit.query == #"FROM (SELECT "id" FROM "Inner" WHERE "id" = $1) as "q", generate_series($2, $3)"#)
        #expect(sourceSplit.values.map { String(describing: $0) } == ["inside", "tail", "end"])
        let joinSplit = join.prepare(.psql).splitted
        #expect(joinSplit.query == #"FROM "Outer" INNER JOIN (SELECT "id" FROM "Inner" WHERE "id" = $1) as "q" ON "enabled" = $2"#)
        #expect(joinSplit.values.map { String(describing: $0) } == ["inside", "yes"])
        let projectionSplit = projection.prepare(.psql).splitted
        #expect(projectionSplit.query == #"SELECT (SELECT "id" FROM "Inner" WHERE "id" = $1), $2"#)
        #expect(projectionSplit.values.map { String(describing: $0) } == ["inside", "outside"])

        #expect(source.prepare(.psql).plain == #"FROM (SELECT "id" FROM "Inner" WHERE "id" = 'inside') as "q", generate_series('tail', 'end')"#)
        let mysql = source.prepare(.mysql).splitted
        #expect(mysql.query == "FROM (SELECT id FROM Inner WHERE id = ?) as q, generate_series(?, ?)")
        #expect(mysql.values.map { String(describing: $0) } == ["inside", "tail", "end"])
        let duck = projection.prepare(.duck).splitted
        #expect(duck.query == #"SELECT (SELECT "id" FROM "Inner" WHERE "id" = $1), $2"#)
        #expect(duck.values.map { String(describing: $0) } == ["inside", "outside"])
    }

    @Test("Empty SELECT projections do not add separators or transfer alias ownership")
    func emptyProjectionOmission() {
        let empty: any SwifQLable = SwifQLableParts(parts: [])
        let first = Select { empty; Path.Column("id") }
        let last = Select { Path.Column("id"); empty }
        let middle = Select { Path.Column("id"); empty; Path.Column("name") }
        let all = Select { empty; empty }
        let aliasBarrier = Select { Path.Column("id"); empty; As("orphan") }
        let conditional = Select {
            Path.Column("id")
            if true { empty }
            Path.Column("name")
        }
        let omittedBranch = Select {
            Path.Column("id")
            if false { empty }
            Path.Column("name")
        }
        let distinct = Select { Distinct(); empty; Path.Column("id") }
        let distinctOn = Select { DistinctOn(Path.Column("country")); empty; Path.Column("id") }
        let projectionDistinct = Select { Distinct(Path.Column("id")); empty; Path.Column("name") }

        #expect(first.prepare(.psql).plain == #"SELECT "id""#)
        #expect(last.prepare(.psql).plain == #"SELECT "id""#)
        #expect(middle.prepare(.psql).plain == #"SELECT "id", "name""#)
        #expect(all.prepare(.psql).plain == "SELECT ")
        #expect(aliasBarrier.prepare(.psql).plain == #"SELECT "id", as "orphan""#)
        #expect(conditional.prepare(.psql).plain == #"SELECT "id", "name""#)
        #expect(omittedBranch.prepare(.psql).plain == conditional.prepare(.psql).plain)
        #expect(distinct.prepare(.psql).plain == #"SELECT DISTINCT "id""#)
        #expect(distinctOn.prepare(.psql).plain == #"SELECT DISTINCT ON ("country") "id""#)
        #expect(projectionDistinct.prepare(.psql).plain == #"SELECT DISTINCT "id", "name""#)
    }

    @Test("USING accepts erased structural key paths and preserves legacy overload ranking")
    func usingCompatibility() {
        let id: any SwifQLable = User.$id
        let single = Using(User.$id)
        let stored = Using(id)
        let multiple = Using(User.$id, User.$name)

        #expect(single.prepare(.psql).plain == #"USING ("id")"#)
        #expect(stored.prepare(.psql).plain == #"USING ("id")"#)
        #expect(multiple.prepare(.psql).plain == #"USING ("id", "name")"#)
        #expect(multiple.prepare(.psql).splitted.values.isEmpty)
        #expect(Using("id").prepare(.psql).plain == #"USING ("id")"#)
        #expect(Using(Path.Column("id")).prepare(.psql).plain == #"USING ("id")"#)
        #expect(Using(\User.$id).prepare(.psql).plain == #"USING ("id")"#)
        #expect(Using(DualUsingInput()).prepare(.psql).plain == #"USING ("legacyName")"#)

        let joined = From {
            Path.Table("Profile")
            Join(.inner, Path.Table("User"))
            Using(User.$id)
        }
        #expect(joined.prepare(.psql).plain == #"FROM "Profile" INNER JOIN "User" USING ("id")"#)
    }

    @Test("Trailing-space structural roots and ordinary aliases keep one separator")
    func postfixSpacingNormalization() {
        let emptySelect = Select {}
        let aliased = emptySelect.as("x")
        let chained = emptySelect.as("x").as("y")
        let spacedScalar = Path.Column("id") ~ SwifQLPartOperator.space

        #expect(emptySelect.prepare(.psql).plain == "SELECT ")
        #expect(aliased.prepare(.psql).plain == #"SELECT as "x""#)
        #expect(From { aliased }.prepare(.psql).plain == #"FROM (SELECT) as "x""#)
        #expect(chained.prepare(.psql).plain == #"SELECT as "x" as "y""#)
        #expect(From { chained }.prepare(.psql).plain == #"FROM (SELECT) as "x" as "y""#)
        #expect(spacedScalar.as("x").prepare(.psql).plain == #""id" as "x""#)
        #expect(Select { Path.Column("id") }.as("x").prepare(.psql).plain == #"SELECT "id" as "x""#)
    }

    @Test("Ordinary aliases and canonical JOIN closure rendering stay unchanged")
    func canonicalControls() {
        let source: any SwifQLable = Select { Path.Column("id") }
        let storedFromAlias = From { source; As("x") }
        let tableAlias = From { Path.Table("User").as("u") }
        let closureJoin = From {
            Path.Table("User")
            Join(.left) {
                Select { Path.Column("id") }
                From { Path.Table("Profile") }
            }
            On(true)
        }

        #expect(storedFromAlias.prepare(.psql).plain == #"FROM (SELECT "id") AS "x""#)
        #expect(tableAlias.prepare(.psql).plain == #"FROM "User" as "u""#)
        #expect(Path.Column("id").as("identifier").prepare(.psql).plain == #""id" as "identifier""#)
        #expect(closureJoin.prepare(.psql).plain == #"FROM "User" LEFT JOIN (SELECT "id" FROM "Profile") ON TRUE"#)
    }
}
