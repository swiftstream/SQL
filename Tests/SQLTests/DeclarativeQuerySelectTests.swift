import Foundation
import Testing
@testable import SQL

private struct SelectAuthoringUser: Table {
    static var tableName: String { "User" }

    @Column("id")
    var id: Int
    @Column("email")
    var email: String
    @Column("name")
    var name: String
    @Column("country")
    var country: String
    @Column("city")
    var city: String

    init() {}
}

private final class CountingPartsChild: SwifQLable {
    private let payload: [SwifQLPart]
    private(set) var partsEvaluationCount = 0

    init(payload: [SwifQLPart]) {
        self.payload = payload
    }

    var parts: [SwifQLPart] {
        partsEvaluationCount += 1
        return payload
    }
}

private func withQueryBuilder(@QueryBuilder _ body: () -> SwifQLable) -> SwifQLable {
    body()
}

@Suite("Declarative SELECT authoring")
struct DeclarativeQuerySelectTests: SwifQLTests {
    private typealias User = SelectAuthoringUser

    // MARK: - S01 ordinary projections

    @Test("S01 ordinary projections")
    func s01OrdinaryProjections() {
        let two = Select {
            User.$id
            User.$email
        }
        check(
            two,
            .psql(#"SELECT "User"."id", "User"."email""#),
            .mysql("SELECT User.id, User.email"),
            .duck(#"SELECT "User"."id", "User"."email""#)
        )

        let three = Select {
            User.$id
            User.$email
            User.$name
        }
        check(
            three,
            .psql(#"SELECT "User"."id", "User"."email", "User"."name""#),
            .mysql("SELECT User.id, User.email, User.name"),
            .duck(#"SELECT "User"."id", "User"."email", "User"."name""#)
        )

        #expect(two.parts.count == 1)
        let root = two.parts.first as? SwifQLStructuralFramePart
        #expect(root?.region == .statement)
    }

    // MARK: - S02 explicit postfix As

    @Test("S02 explicit postfix As")
    func s02ExplicitPostfixAs() {
        let built = Select {
            User.$id
            As("identifier")

            User.$email
            As("emailAddress")
        }
        check(
            built,
            .psql(#"SELECT "User"."id" as "identifier", "User"."email" as "emailAddress""#),
            .mysql("SELECT User.id as identifier, User.email as emailAddress"),
            .duck(#"SELECT "User"."id" as "identifier", "User"."email" as "emailAddress""#)
        )
        #expect(built.prepare(.psql).splitted.values.isEmpty)
        #expect(!built.prepare(.psql).plain.contains(#"id,"#))
        #expect(built.prepare(.psql).plain.contains(#""identifier", "User"."email""#))
    }

    // MARK: - S03 alias spelling equivalence

    @Test("S03 alias spelling equivalence")
    func s03AliasSpellingEquivalence() {
        let explicit = Select {
            User.$id
            As("identifier")
        }
        let fluent = Select {
            User.$id.as("identifier")
        }
        let operatorForm = Select {
            User.$name => "displayName"
        }
        let mixed = Select {
            User.$id
            As("identifier")

            User.$email.as("emailAddress")

            User.$name => "displayName"
        }

        check(explicit,
            .psql(#"SELECT "User"."id" as "identifier""#),
            .mysql("SELECT User.id as identifier"),
            .duck(#"SELECT "User"."id" as "identifier""#)
        )
        check(fluent,
            .psql(#"SELECT "User"."id" as "identifier""#),
            .mysql("SELECT User.id as identifier"),
            .duck(#"SELECT "User"."id" as "identifier""#)
        )
        #expect(explicit.prepare(.psql).plain == fluent.prepare(.psql).plain)
        #expect(explicit.prepare(.psql).splitted.query == fluent.prepare(.psql).splitted.query)

        check(operatorForm,
            .psql(#"SELECT "User"."name" as "displayName""#),
            .mysql("SELECT User.name as displayName"),
            .duck(#"SELECT "User"."name" as "displayName""#)
        )

        check(
            mixed,
            .psql(#"SELECT "User"."id" as "identifier", "User"."email" as "emailAddress", "User"."name" as "displayName""#),
            .mysql("SELECT User.id as identifier, User.email as emailAddress, User.name as displayName"),
            .duck(#"SELECT "User"."id" as "identifier", "User"."email" as "emailAddress", "User"."name" as "displayName""#)
        )

        #expect(explicit.prepare(.psql).splitted.values.isEmpty)
        #expect(fluent.prepare(.psql).splitted.values.isEmpty)
        #expect(operatorForm.prepare(.psql).splitted.values.isEmpty)
        #expect(mixed.prepare(.psql).splitted.values.isEmpty)

        // existing generic .as(SwifQLable) for non-String expressions remains available
        let genericAs = User.$id.as(User.$name)
        #expect(genericAs.prepare(.psql).plain.contains("as"))
        #expect(genericAs.prepare(.psql).plain.contains(#""User"."name""#))

        // existing => implementation is untouched (identifier alias, zero binds)
        let arrow = User.$email => "emailAddress"
        #expect(arrow.prepare(.psql).plain == #" "User"."email" as "emailAddress""#.trimmingCharacters(in: .whitespaces)
            || arrow.prepare(.psql).plain == #""User"."email" as "emailAddress""#)
        #expect(arrow.prepare(.psql).splitted.values.isEmpty)
    }

    // MARK: - S04 conditional projection + alias

    @Test("S04 conditional projection + alias")
    func s04ConditionalProjectionAndAlias() {
        let includeEmail = true
        let present = Select {
            User.$id

            if includeEmail {
                User.$email
                As("emailAddress")
            }
        }
        check(
            present,
            .psql(#"SELECT "User"."id", "User"."email" as "emailAddress""#),
            .mysql("SELECT User.id, User.email as emailAddress"),
            .duck(#"SELECT "User"."id", "User"."email" as "emailAddress""#)
        )

        let absent = Select {
            User.$id

            if false {
                User.$email
                As("emailAddress")
            }
        }
        check(
            absent,
            .psql(#"SELECT "User"."id""#),
            .mysql("SELECT User.id"),
            .duck(#"SELECT "User"."id""#)
        )
        #expect(!absent.prepare(.psql).plain.contains("email"))
        #expect(!absent.prepare(.psql).plain.contains("emailAddress"))
    }

    // MARK: - S05 if/else, optional binding, loop

    @Test("S05 if/else, optional binding, loop")
    func s05ControlFlowGroups() {
        let useEmail = true
        let branched = Select {
            if useEmail {
                User.$email
                As("emailAddress")
            } else {
                User.$name
                As("displayName")
            }
        }
        check(branched,
            .psql(#"SELECT "User"."email" as "emailAddress""#),
            .mysql("SELECT User.email as emailAddress"),
            .duck(#"SELECT "User"."email" as "emailAddress""#)
        )

        let useName = false
        let otherBranch = Select {
            if useName {
                User.$email
                As("emailAddress")
            } else {
                User.$name
                As("displayName")
            }
        }
        check(otherBranch,
            .psql(#"SELECT "User"."name" as "displayName""#),
            .mysql("SELECT User.name as displayName"),
            .duck(#"SELECT "User"."name" as "displayName""#)
        )

        let maybeName: String? = "nick"
        let bound = Select {
            User.$id

            if let maybeName {
                User.$name
                As(maybeName)
            }
        }
        check(bound,
            .psql(#"SELECT "User"."id", "User"."name" as "nick""#),
            .mysql("SELECT User.id, User.name as nick"),
            .duck(#"SELECT "User"."id", "User"."name" as "nick""#)
        )

        let missing: String? = nil
        let unbound = Select {
            User.$id

            if let missing {
                User.$name
                As(missing)
            }
        }
        check(unbound,
            .psql(#"SELECT "User"."id""#),
            .mysql("SELECT User.id"),
            .duck(#"SELECT "User"."id""#)
        )

        let looped = Select {
            for alias in ["a", "b"] {
                User.$id
                As(alias)
            }
        }
        check(looped,
            .psql(#"SELECT "User"."id" as "a", "User"."id" as "b""#),
            .mysql("SELECT User.id as a, User.id as b"),
            .duck(#"SELECT "User"."id" as "a", "User"."id" as "b""#)
        )

        let ordered = Select {
            User.$id

            if useEmail {
                User.$email
                As("emailAddress")
            }

            User.$name
        }
        check(ordered,
            .psql(#"SELECT "User"."id", "User"."email" as "emailAddress", "User"."name""#),
            .mysql("SELECT User.id, User.email as emailAddress, User.name"),
            .duck(#"SELECT "User"."id", "User"."email" as "emailAddress", "User"."name""#)
        )
    }

    // MARK: - S06 canonical Distinct()

    @Test("S06 canonical Distinct()")
    func s06CanonicalDistinct() {
        let built = Select {
            Distinct()
            User.$id
            User.$email
        }
        check(
            built,
            .psql(#"SELECT DISTINCT "User"."id", "User"."email""#),
            .mysql("SELECT DISTINCT User.id, User.email"),
            .duck(#"SELECT DISTINCT "User"."id", "User"."email""#)
        )
    }

    // MARK: - S07 optional Distinct()

    @Test("S07 optional Distinct()")
    func s07OptionalDistinct() {
        let useDistinct = true
        let on = Select {
            if useDistinct {
                Distinct()
            }

            User.$id
            User.$email
        }
        check(
            on,
            .psql(#"SELECT DISTINCT "User"."id", "User"."email""#),
            .mysql("SELECT DISTINCT User.id, User.email"),
            .duck(#"SELECT DISTINCT "User"."id", "User"."email""#)
        )

        let off = Select {
            if false {
                Distinct()
            }

            User.$id
            User.$email
        }
        check(
            off,
            .psql(#"SELECT "User"."id", "User"."email""#),
            .mysql("SELECT User.id, User.email"),
            .duck(#"SELECT "User"."id", "User"."email""#)
        )
        #expect(!off.prepare(.psql).plain.contains("DISTINCT"))
        #expect(!off.prepare(.psql).plain.contains("  "))
        #expect(!off.prepare(.psql).plain.contains(", ,"))
    }

    // MARK: - S08 modifier if/else choice

    @Test("S08 modifier if/else choice")
    func s08ModifierIfElse() {
        let useDistinctOn = true
        let onBranch = Select {
            if useDistinctOn {
                DistinctOn(User.$country)
            } else {
                Distinct()
            }

            User.$id
        }
        check(
            onBranch,
            .psql(#"SELECT DISTINCT ON ("User"."country") "User"."id""#),
            .mysql("SELECT DISTINCT ON (User.country) User.id"),
            .duck(#"SELECT DISTINCT ON ("User"."country") "User"."id""#)
        )

        let useDistinct = false
        let distinctBranch = Select {
            if useDistinct {
                DistinctOn(User.$country)
            } else {
                Distinct()
            }

            User.$id
        }
        check(
            distinctBranch,
            .psql(#"SELECT DISTINCT "User"."id""#),
            .mysql("SELECT DISTINCT User.id"),
            .duck(#"SELECT DISTINCT "User"."id""#)
        )
    }

    // MARK: - S09 historical field-bearing Distinct

    @Test("S09 historical field-bearing Distinct")
    func s09HistoricalFieldBearingDistinct() {
        let single = Select {
            Distinct(User.$id)
            User.$email
        }
        check(
            single,
            .psql(#"SELECT DISTINCT "User"."id", "User"."email""#),
            .mysql("SELECT DISTINCT User.id, User.email"),
            .duck(#"SELECT DISTINCT "User"."id", "User"."email""#)
        )

        let multiple = Select {
            Distinct(User.$id, User.$name)
            User.$email
        }
        check(
            multiple,
            .psql(#"SELECT DISTINCT "User"."id", "User"."name", "User"."email""#),
            .mysql("SELECT DISTINCT User.id, User.name, User.email"),
            .duck(#"SELECT DISTINCT "User"."id", "User"."name", "User"."email""#)
        )
    }

    // MARK: - S10 historical Distinct(on:)

    @Test("S10 historical Distinct(on:)")
    func s10HistoricalDistinctOn() {
        let built = Select {
            Distinct(on: User.$country)
            User.$id
        }
        check(
            built,
            .psql(#"SELECT DISTINCT ON ("User"."country") "User"."id""#),
            .mysql("SELECT DISTINCT ON (User.country) User.id"),
            .duck(#"SELECT DISTINCT ON ("User"."country") "User"."id""#)
        )

        let withMore = Select {
            Distinct(on: User.$country, User.$city)
            User.$id
            User.$email
        }
        check(
            withMore,
            .psql(#"SELECT DISTINCT ON ("User"."country", "User"."city") "User"."id", "User"."email""#),
            .mysql("SELECT DISTINCT ON (User.country, User.city) User.id, User.email"),
            .duck(#"SELECT DISTINCT ON ("User"."country", "User"."city") "User"."id", "User"."email""#)
        )
    }

    // MARK: - S11 builder-first DistinctOn

    @Test("S11 builder-first DistinctOn")
    func s11BuilderFirstDistinctOn() {
        let built = Select {
            DistinctOn {
                User.$country
                User.$city
            }
            User.$id
        }
        check(
            built,
            .psql(#"SELECT DISTINCT ON ("User"."country", "User"."city") "User"."id""#),
            .mysql("SELECT DISTINCT ON (User.country, User.city) User.id"),
            .duck(#"SELECT DISTINCT ON ("User"."country", "User"."city") "User"."id""#)
        )
    }

    // MARK: - S12 concise DistinctOn

    @Test("S12 concise DistinctOn")
    func s12ConciseDistinctOn() {
        let concise = Select {
            DistinctOn(User.$country, User.$city)
            User.$id
        }
        let builder = Select {
            DistinctOn {
                User.$country
                User.$city
            }
            User.$id
        }
        check(
            concise,
            .psql(#"SELECT DISTINCT ON ("User"."country", "User"."city") "User"."id""#),
            .mysql("SELECT DISTINCT ON (User.country, User.city) User.id"),
            .duck(#"SELECT DISTINCT ON ("User"."country", "User"."city") "User"."id""#)
        )
        #expect(concise.prepare(.psql).plain == builder.prepare(.psql).plain)
        #expect(concise.prepare(.mysql).plain == builder.prepare(.mysql).plain)
        #expect(concise.prepare(.duck).plain == builder.prepare(.duck).plain)
    }

    // MARK: - S13 no MySQL DistinctOn emulation

    @Test("S13 no MySQL DistinctOn emulation")
    func s13NoMySQLDistinctOnEmulation() {
        let builderForm = Select {
            DistinctOn {
                User.$country
            }
            User.$id
        }
        let conciseForm = Select {
            DistinctOn(User.$country)
            User.$id
        }

        for built in [builderForm, conciseForm] {
            let mysql = built.prepare(.mysql)
            #expect(mysql.plain.contains("DISTINCT ON"))
            #expect(!mysql.plain.contains("GROUP BY"))
            #expect(!mysql.plain.contains("ROW_NUMBER"))
            #expect(!mysql.plain.contains("OVER"))
            #expect(!mysql.plain.contains("PARTITION"))
            #expect(mysql.plain == "SELECT DISTINCT ON (User.country) User.id")
        }

        #expect(builderForm.prepare(.psql).plain.contains("DISTINCT ON"))
        #expect(builderForm.prepare(.duck).plain.contains("DISTINCT ON"))
    }

    // MARK: - S14 header/projection comma ownership

    @Test("S14 header/projection comma ownership")
    func s14HeaderProjectionCommaOwnership() {
        let headerOnlySpacing = Select {
            Distinct()
            User.$id
        }
        check(headerOnlySpacing,
            .psql(#"SELECT DISTINCT "User"."id""#),
            .mysql("SELECT DISTINCT User.id"),
            .duck(#"SELECT DISTINCT "User"."id""#)
        )
        #expect(!headerOnlySpacing.prepare(.psql).plain.contains("DISTINCT,"))
        #expect(!headerOnlySpacing.prepare(.psql).plain.contains("DISTINCT  "))

        let fieldBearingComma = Select {
            Distinct(User.$id)
            User.$email
            User.$name
        }
        check(
            fieldBearingComma,
            .psql(#"SELECT DISTINCT "User"."id", "User"."email", "User"."name""#),
            .mysql("SELECT DISTINCT User.id, User.email, User.name"),
            .duck(#"SELECT DISTINCT "User"."id", "User"."email", "User"."name""#)
        )

        let aliasedCurrentComma = Select {
            User.$id
            As("identifier")

            User.$email
        }
        check(
            aliasedCurrentComma,
            .psql(#"SELECT "User"."id" as "identifier", "User"."email""#),
            .mysql("SELECT User.id as identifier, User.email"),
            .duck(#"SELECT "User"."id" as "identifier", "User"."email""#)
        )
    }

    // MARK: - S15 unsafe projection bind order

    @Test("S15 unsafe projection bind order")
    func s15UnsafeProjectionBindOrder() {
        let built = Select {
            "alpha"
            7
            "omega"
        }
        check(
            built,
            .psql("SELECT 'alpha', 7, 'omega'", "SELECT $1, $2, $3"),
            .mysql("SELECT 'alpha', 7, 'omega'", "SELECT ?, ?, ?"),
            .duck("SELECT 'alpha', 7, 'omega'", "SELECT $1, $2, $3")
        )

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let splitted = built.prepare(dialect).splitted
            #expect(splitted.values.count == 3)
            #expect(splitted.values[0] as? String == "alpha")
            #expect(splitted.values[1] as? Int == 7)
            #expect(splitted.values[2] as? String == "omega")
        }
    }

    // MARK: - S16 DistinctOn key bind order

    @Test("S16 DistinctOn key bind order")
    func s16DistinctOnKeyBindOrder() {
        let built = Select {
            DistinctOn("cn", "bj")
            User.$id
            "tail"
        }
        check(
            built,
            .psql(
                #"SELECT DISTINCT ON ('cn', 'bj') "User"."id", 'tail'"#,
                "SELECT DISTINCT ON ($1, $2) \"User\".\"id\", $3"
            ),
            .mysql(
                "SELECT DISTINCT ON ('cn', 'bj') User.id, 'tail'",
                "SELECT DISTINCT ON (?, ?) User.id, ?"
            ),
            .duck(
                #"SELECT DISTINCT ON ('cn', 'bj') "User"."id", 'tail'"#,
                "SELECT DISTINCT ON ($1, $2) \"User\".\"id\", $3"
            )
        )

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let splitted = built.prepare(dialect).splitted
            #expect(splitted.values.count == 3)
            #expect(splitted.values[0] as? String == "cn")
            #expect(splitted.values[1] as? String == "bj")
            #expect(splitted.values[2] as? String == "tail")
        }

        let builderKeys = Select {
            DistinctOn {
                "k1"
                "k2"
            }
            "p1"
        }
        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let splitted = builderKeys.prepare(dialect).splitted
            #expect(splitted.values.map { "\($0)" } == ["k1", "k2", "p1"])
        }
    }

    // MARK: - S17 stateful projection single evaluation

    @Test("S17 stateful projection single evaluation")
    func s17StatefulProjectionSingleEvaluation() {
        let first = CountingPartsChild(payload: [SwifQLPartOperator.custom("FIRST")])
        let second = CountingPartsChild(payload: [SwifQLPartOperator.custom("SECOND")])

        let built = Select {
            first
            As("a")
            second
        }

        #expect(first.partsEvaluationCount == 1)
        #expect(second.partsEvaluationCount == 1)

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            _ = built.prepare(dialect)
        }
        #expect(first.partsEvaluationCount == 1)
        #expect(second.partsEvaluationCount == 1)

        let aliasOnly = CountingPartsChild(payload: [SwifQLPartOperator.custom("ALIASED")])
        let aliased = Select {
            aliasOnly
            As("kept")
        }
        #expect(aliasOnly.partsEvaluationCount == 1)
        for dialect in [SQLDialect.psql, .mysql, .duck] {
            _ = aliased.prepare(dialect)
        }
        #expect(aliasOnly.partsEvaluationCount == 1)

        let keyChild = CountingPartsChild(payload: [SwifQLPartOperator.custom("KEY")])
        let projectionChild = CountingPartsChild(payload: [SwifQLPartOperator.custom("PROJ")])
        let distinctOnBuilt = Select {
            DistinctOn(keyChild)
            projectionChild
        }
        #expect(keyChild.partsEvaluationCount == 1)
        #expect(projectionChild.partsEvaluationCount == 1)
        for dialect in [SQLDialect.psql, .mysql, .duck] {
            _ = distinctOnBuilt.prepare(dialect)
        }
        #expect(keyChild.partsEvaluationCount == 1)
        #expect(projectionChild.partsEvaluationCount == 1)
    }

    // MARK: - S18 root/legacy compatibility

    @Test("S18 root/legacy compatibility")
    func s18RootLegacyCompatibility() {
        let bare = Select
        #expect(bare.prepare(.psql).plain == "SELECT")

        let varargs = Select("hello", 1)
        check(
            varargs,
            .psql("SELECT 'hello', 1"),
            .mysql("SELECT 'hello', 1"),
            .duck("SELECT 'hello', 1")
        )

        let array = Select([SwifQLableParts(parts: SwifQLPartOperator.custom("X"))])
        check(array, all: "SELECT X")

        let declarative = Select {
            User.$id
        }
        check(
            declarative,
            .psql(#"SELECT "User"."id""#),
            .mysql("SELECT User.id"),
            .duck(#"SELECT "User"."id""#)
        )

        let wrapped = SwifQL {
            Select {
                User.$id
            }
        }
        check(
            wrapped,
            .psql(#"SELECT "User"."id""#),
            .mysql("SELECT User.id"),
            .duck(#"SELECT "User"."id""#)
        )
        #expect(wrapped.prepare(.psql).plain == declarative.prepare(.psql).plain)
        #expect(wrapped.parts.count == 1)
        #expect(wrapped.parts.first is SwifQLStructuralFramePart)

        let qb = withQueryBuilder {
            Select {
                User.$id
            }
        }
        #expect(qb.prepare(.psql).plain.contains("SELECT"))

        let rootWrapped = SwifQL(declarative)
        #expect(rootWrapped.prepare(.psql).plain == declarative.prepare(.psql).plain)

        let legacyDistinct = Distinct(User.$id)
        check(
            legacyDistinct,
            .psql(#"DISTINCT "User"."id""#),
            .mysql("DISTINCT User.id"),
            .duck(#"DISTINCT "User"."id""#)
        )
        let legacyDistinctOn = Distinct(on: User.$country)
        check(
            legacyDistinctOn,
            .psql(#"DISTINCT ON ("User"."country")"#),
            .mysql("DISTINCT ON (User.country)"),
            .duck(#"DISTINCT ON ("User"."country")"#)
        )
        let legacySelect = SwifQL.select(legacyDistinct)
        #expect(legacySelect.prepare(.psql).plain == #"SELECT DISTINCT "User"."id""#)
    }
}
