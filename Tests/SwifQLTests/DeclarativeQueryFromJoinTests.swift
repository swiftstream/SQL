import Foundation
import Testing
@testable import SwifQL

private struct DQ04Table: Decodable {}

private final class DQ04EvaluationCounter {
    var count = 0
}

private struct DQ04CountedSource: SwifQLable {
    let counter: DQ04EvaluationCounter

    var parts: [SwifQLPart] {
        counter.count += 1
        return Path.Table("User").parts
    }
}

@Suite("Declarative FROM and JOIN authoring")
struct DeclarativeQueryFromJoinTests: SwifQLTests {
    @Test("D04-S01 FROM sources own commas")
    func s01FromSourcesOwnCommas() {
        let query = From {
            Path.Table("User")
            Path.Table("Profile")
            Path.Table("Organization")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User", "Profile", "Organization""#)
    }

    @Test("D04-S02 source explicit alias")
    func s02SourceExplicitAlias() {
        let query = From { Path.Table("User"); As("u") }
        #expect(query.prepare(.psql).plain == #"FROM "User" AS "u""#)
        #expect(query.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("D04-S03 source fluent and operator aliases remain compatible")
    func s03SourceAliasCompatibility() {
        let fluent = From { Path.Table("User").as("u") }
        let operatorForm = From { Path.Table("User") => "u" }
        #expect(fluent.prepare(.psql).plain == #"FROM "User" as "u""#)
        #expect(operatorForm.prepare(.psql).plain == #"FROM "User" as "u""#)
    }

    @Test("D04-S04 Columns treats names as identifiers")
    func s04ColumnsIdentifierSafety() {
        let query = From { Path.Table("User"); As("u"); Columns("id", "display name") }
        #expect(query.prepare(.psql).plain == #"FROM "User" AS "u" ("id", "display name")"#)
        #expect(query.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("D04-S05 dynamic Columns includes its true branch")
    func s05DynamicColumnsTrueBranch() {
        let includeName = true
        let query = From {
            Path.Table("User")
            As("u")
            Columns {
                "id"
                if includeName { "name" }
            }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" AS "u" ("id", "name")"#)
    }

    @Test("D04-S06 empty dynamic Columns omits the continuation")
    func s06DynamicColumnsEmptyOmission() {
        let includeName = false
        let query = From {
            Path.Table("User")
            As("u")
            Columns { if includeName { "name" } }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" AS "u""#)
    }

    @Test("D04-S07 WITH ORDINALITY alias and Columns order")
    func s07WithOrdinalityOrder() {
        let query = From {
            Fn.generateSeries(10, 12)
            WithOrdinality()
            As("series")
            Columns("value", "position")
        }
        #expect(query.prepare(.psql).plain == #"FROM generate_series(10, 12) WITH ORDINALITY AS "series" ("value", "position")"#)
    }

    @Test("D04-S08 conditional complete source")
    func s08ConditionalCompleteSource() {
        let includeProfile = true
        let query = From {
            Path.Table("User")
            if includeProfile {
                Path.Table("Profile")
                As("profile")
            }
            Path.Table("Organization")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User", "Profile" AS "profile", "Organization""#)
    }

    @Test("D04-S09 if else complete source")
    func s09IfElseCompleteSource() {
        let useProfile = false
        let query = From {
            if useProfile {
                Path.Table("Profile")
                As("profile")
            } else {
                Path.Table("Guest")
            }
            Path.Table("Organization")
        }
        #expect(query.prepare(.psql).plain == #"FROM "Guest", "Organization""#)
    }

    @Test("D04-S10 loop materializes complete sources")
    func s10LoopCompleteSources() {
        let query = From {
            for name in ["User", "Profile"] {
                Path.Table(name)
            }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User", "Profile""#)
    }

    @Test("D04-S11 direct nested SELECT FROM alias")
    func s11DirectNestedSelectFromAlias() {
        let query = From {
            Select { Path.Table("Order").column("userId") }
            From { Path.Table("Order") }
            As("orders")
        }
        #expect(query.prepare(.psql).plain == #"FROM (SELECT "Order"."userId" FROM "Order") AS "orders""#)
    }

    @Test("D04-S12 nested statement finalizes before next outer source")
    func s12NestedSourceFinalizedByOuterSource() {
        let query = From {
            Select { Path.Table("Order").column("id") }
            From { Path.Table("Order") }
            Path.Table("Organization")
        }
        #expect(query.prepare(.psql).plain == #"FROM (SELECT "Order"."id" FROM "Order"), "Organization""#)
    }

    @Test("D04-S13 conditional complete nested source")
    func s13ConditionalNestedSource() {
        let includeOrders = true
        let query = From {
            if includeOrders {
                Select { Path.Table("Order").column("userId") }
                From { Path.Table("Order") }
                As("orders")
            }
            Path.Table("Organization")
        }
        #expect(query.prepare(.psql).plain == #"FROM (SELECT "Order"."userId" FROM "Order") AS "orders", "Organization""#)
    }

    @Test("D04-S14 explicit SwifQL root is an already formed source")
    func s14ExplicitCurrentRootSource() {
        let nested = SwifQL {
            Select { Path.Table("Order").column("id") }
            From { Path.Table("Order") }
        }
        let query = From { nested; As("orders") }
        #expect(query.prepare(.psql).plain == #"FROM (SELECT "Order"."id" FROM "Order") AS "orders""#)
    }

    @Test("D04-S15 JOIN ON builder AND composition")
    func s15JoinOnBuilder() {
        let query = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile"))
            On {
                Path.Table("User").column("id") == Path.Table("Profile").column("userId")
                Path.Table("Profile").column("active") == true
            }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" ON "User"."id" = "Profile"."userId" AND "Profile"."active" = TRUE"#)
    }

    @Test("D04-S16 JOIN source alias and ON")
    func s16JoinAliasAndOn() {
        let query = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile"))
            As("profile")
            On(Path.Table("User").column("id") == Path.Table("Profile").column("userId"))
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" AS "profile" ON "User"."id" = "Profile"."userId""#)
    }

    @Test("D04-S17 JOIN USING")
    func s17JoinUsing() {
        let query = From { Path.Table("User"); Join(.left, Path.Table("Profile")); Using("id", "accountId") }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" USING ("id", "accountId")"#)
    }

    @Test("D04-S18 JOIN source alias and USING")
    func s18JoinAliasAndUsing() {
        let query = From { Path.Table("User"); Join(.left, Path.Table("Profile")); As("profile"); Using("id") }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" AS "profile" USING ("id")"#)
    }

    @Test("D04-S19 JOIN USING result alias")
    func s19JoinUsingResultAlias() {
        let query = From { Path.Table("User"); Join(.left, Path.Table("Profile")); Using("id"); As("keys") }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" USING ("id") AS "keys""#)
    }

    @Test("D04-S20 JOIN source and USING result aliases have distinct owners")
    func s20JoinDistinctAliasOwners() {
        let query = From { Path.Table("User"); Join(.left, Path.Table("Profile")); As("profile"); Using("id"); As("keys") }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" AS "profile" USING ("id") AS "keys""#)
    }

    @Test("D04-S21 independent JOIN items preserve order")
    func s21TwoIndependentJoins() {
        let query = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile"))
            On(true)
            Join(.inner, Path.Table("Account"))
            Using("id")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" ON TRUE INNER JOIN "Account" USING ("id")"#)
    }

    @Test("D04-S22 conditional complete JOIN")
    func s22ConditionalJoin() {
        let includeProfile = true
        let query = From {
            Path.Table("User")
            if includeProfile {
                Join(.left, Path.Table("Profile"))
                As("profile")
                On(true)
            }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" AS "profile" ON TRUE"#)
    }

    @Test("D04-S23 left lateral structural source")
    func s23LeftLateralNestedSource() {
        let query = From {
            Path.Table("User")
            Join(.leftLateral) {
                Select {
                    Path.Table("Post").column("id")
                    Path.Table("Post").column("createdAt")
                }
                From { Path.Table("Post") }
            }
            As("latestPost")
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN LATERAL (SELECT "Post"."id", "Post"."createdAt" FROM "Post") AS "latestPost" ON TRUE"#)
    }

    @Test("D04-S24 source owning TABLESAMPLE canonical initializer and legacy compatibility")
    func s24TableSampleCompatibility() {
        let sourceOwned = TableSample(DQ04Table.table) {
            System(10)
            Repeatable(42)
        }
        #expect(sourceOwned.prepare(.duck).plain == #""DQ04Table" TABLESAMPLE system(10 PERCENT) REPEATABLE (42)"#)
        #expect(sourceOwned.prepare(.psql).plain == #""DQ04Table" TABLESAMPLE system(10 PERCENT) REPEATABLE (42)"#)
        #expect(sourceOwned.method == .system)
        #expect(sourceOwned.arguments.count == 1)
        #expect(sourceOwned.arguments[0].role == .percentage)
        #expect(sourceOwned.repeatable?.value.prepare(.duck).plain == "42")

        let legacySize = TableSample(SampleSize(percentage: 10))
        let legacyArguments = TableSample(arguments: [SampleArgument(rows: 7)], method: .system)
        let legacyRepeatable = TableSample(SampleSize(percentage: 10), method: .reservoir, repeatable: 42)
        #expect(legacySize.parts.count == 1)
        #expect(legacySize.parts.first is SwifQLPartSampling)
        #expect(legacySize.prepare(.duck).plain == "TABLESAMPLE (10 PERCENT)")
        #expect(legacyArguments.prepare(.duck).plain == "TABLESAMPLE system(7 ROWS)")
        #expect(legacyRepeatable.prepare(.duck).plain == "TABLESAMPLE reservoir(10 PERCENT) REPEATABLE (42)")
        #expect(DQ04Table.table.tableSample(legacyRepeatable).prepare(.duck).plain == #""DQ04Table" TABLESAMPLE reservoir(10 PERCENT) REPEATABLE (42)"#)

        let customMethod = SampleMethod(namespace: "vendor", name: "stratified")
        let openLegacy = TableSample(arguments: [SampleArgument(percentage: 10)], method: customMethod)
        let openSourceOwned = TableSample(
            source: DQ04Table.table,
            options: TableSampleBuilder.Options(
                arguments: [SampleArgument(percentage: 10)],
                method: customMethod
            )
        )
        #expect(openLegacy.method == customMethod)
        #expect(openSourceOwned.method == customMethod)
        #expect(openSourceOwned.prepare(.duck).plain == #""DQ04Table" TABLESAMPLE stratified(10 PERCENT)"#)
    }

    @Test("D04-S25 source owning TABLESAMPLE is one aliased FROM item")
    func s25TableSampleFromItem() {
        let query = From {
            TableSample(DQ04Table.table) {
                Bernoulli(10)
            }
            As("sampledUsers")
        }
        #expect(query.prepare(.duck).plain == #"FROM "DQ04Table" TABLESAMPLE bernoulli(10 PERCENT) AS "sampledUsers""#)
    }

    @Test("D04-S26 bind order and source parts evaluation")
    func s26PreparationObservation() {
        let counter = DQ04EvaluationCounter()
        let sample = TableSample(DQ04CountedSource(counter: counter)) {
            System(10)
            Repeatable(42)
        }
        #expect(counter.count == 1)

        let query = SwifQL {
            Select { Path.Table("User").column("id") }
            From {
                sample
                As("sampledUsers")
                Join(.left, Path.Table("Profile"))
                On {
                    Path.Table("User").column("id") == 101
                    Path.Table("Profile").column("userId") == 202
                }
            }
        }
        let prepared = query.prepareObservingUnsafeValues(.duck)
        #expect(prepared.prepared.splitted.values.map { String(describing: $0) } == ["101", "202"])
        if case let .complete(occurrences) = prepared.unsafeValueTrace {
            #expect(occurrences.compactMap { $0.value as? Int } == [101, 202])
            #expect(occurrences.map(\.disposition) == [.bound(index: 0), .bound(index: 1)])
        } else {
            #expect(Bool(false))
        }
        #expect(prepared.prepared.plain == #"SELECT "User"."id" FROM "User" TABLESAMPLE system(10 PERCENT) REPEATABLE (42) AS "sampledUsers" LEFT JOIN "Profile" ON "User"."id" = 101 AND "Profile"."userId" = 202"#)
        _ = query.parts
        _ = query.prepare(.duck)
        #expect(counter.count == 1)
    }

    @Test("D04-S27 fluent JOIN source alias keeps typed ON ownership")
    func s27FluentJoinSourceAlias() {
        let explicit = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile"))
            As("profile")
            On(Path.Table("User").column("id") == Path.Table("Profile").column("userId"))
        }
        let fluent = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile")).as("profile")
            On(Path.Table("User").column("id") == Path.Table("Profile").column("userId"))
        }
        #expect(fluent.prepare(.psql).plain == explicit.prepare(.psql).plain)
        #expect(fluent.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" AS "profile" ON "User"."id" = "Profile"."userId""#)
        #expect(fluent.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("D04-S28 operator JOIN source alias keeps typed USING ownership")
    func s28OperatorJoinSourceAlias() {
        let query = From {
            Path.Table("User")
            Join(.left, Path.Table("Profile")) => "profile name"
            Using("id")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" AS "profile name" USING ("id")"#)
        #expect(query.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("D04-S29 fluent nested JOIN alias keeps typed ON ownership")
    func s29FluentNestedJoinAlias() {
        let query = From {
            Path.Table("User")
            Join(.leftLateral) {
                Select { Path.Table("Post").column("id") }
                From { Path.Table("Post") }
            }.as("latestPost")
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN LATERAL (SELECT "Post"."id" FROM "Post") AS "latestPost" ON TRUE"#)
        #expect(query.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("D04-S30 operator nested JOIN alias keeps typed ON ownership")
    func s30OperatorNestedJoinAlias() {
        let query = From {
            Path.Table("User")
            Join(.leftLateral) {
                Select { Path.Table("Post").column("id") }
                From { Path.Table("Post") }
            } => "latestPost"
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN LATERAL (SELECT "Post"."id" FROM "Post") AS "latestPost" ON TRUE"#)
        #expect(query.prepare(.psql).splitted.values.isEmpty)
    }

    @Test("D04-S31 conditional multiple JOINs stay attached to a real source")
    func s31ConditionalMultipleJoinContinuation() {
        let includeBoth = true
        let query = From {
            Path.Table("User")
            if includeBoth {
                Join(.left, Path.Table("Profile"))
                On(true)
                Join(.inner, Path.Table("Account"))
                Using("id")
            }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Profile" ON TRUE INNER JOIN "Account" USING ("id")"#)

        let includeNeither = false
        let withoutJoins = From {
            Path.Table("User")
            if includeNeither {
                Join(.left, Path.Table("Profile"))
                On(true)
                Join(.inner, Path.Table("Account"))
                Using("id")
            }
        }
        #expect(withoutJoins.prepare(.psql).plain == #"FROM "User""#)
    }

    @Test("D04-S32 if else JOIN branches preserve source attachment")
    func s32IfElseJoinAttachment() {
        let useProfile = false
        let query = From {
            Path.Table("User")
            if useProfile {
                Join(.left, Path.Table("Profile"))
                On(true)
            } else {
                Join(.inner, Path.Table("Account"))
                Using("id")
            }
        }
        #expect(query.prepare(.psql).plain == #"FROM "User" INNER JOIN "Account" USING ("id")"#)
    }

    @Test("D04-S33 source loop preserves a later source")
    func s33SourceLoopThenSource() {
        let query = From {
            for name in ["User", "Profile"] {
                Path.Table(name)
            }
            Path.Table("Organization")
        }
        #expect(query.prepare(.psql).plain == #"FROM "User", "Profile", "Organization""#)

        let emptyLoop = From {
            for name in [String]() {
                Path.Table(name)
            }
            Path.Table("Organization")
        }
        #expect(emptyLoop.prepare(.psql).plain == #"FROM "Organization""#)
    }

    @Test("D04-S34 optional source then guaranteed source keeps JOIN ownership")
    func s34OptionalSourceThenSourceThenJoin() {
        let includeProfile = true
        let withOptionalSource = From {
            if includeProfile {
                Path.Table("Profile")
            }
            Path.Table("User")
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(withOptionalSource.prepare(.psql).plain == #"FROM "Profile", "User" LEFT JOIN "Account" ON TRUE"#)

        let omitProfile = false
        let withoutOptionalSource = From {
            if omitProfile {
                Path.Table("Profile")
            }
            Path.Table("User")
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(withoutOptionalSource.prepare(.psql).plain == #"FROM "User" LEFT JOIN "Account" ON TRUE"#)
    }

    @Test("D04-S35 JOIN attaches to the immediately preceding source")
    func s35TwoSourcesThenJoin() {
        let query = From {
            Path.Table("User")
            Path.Table("Profile")
            Join(.left, Path.Table("Account"))
            On(true)
        }
        #expect(query.prepare(.psql).plain == #"FROM "User", "Profile" LEFT JOIN "Account" ON TRUE"#)
    }

    @Test("D04-S36 loop-only empty source list renders invalid caller input")
    func s36LoopOnlyEmptySourceListObservation() {
        let query = From {
            for name in [String]() {
                Path.Table(name)
            }
        }
        // D3 observation only: an empty FROM source list is invalid caller input.
        #expect(query.prepare(.psql).plain == "FROM ")
    }

    @Test("D04-S37 optional-only source list renders invalid caller input when absent")
    func s37OptionalOnlySourceListObservation() {
        let includeUser = true
        let present = From {
            if includeUser {
                Path.Table("User")
            }
        }
        #expect(present.prepare(.psql).plain == #"FROM "User""#)

        let omitUser = false
        let absent = From {
            if omitUser {
                Path.Table("User")
            }
        }
        // D4 observation only: an absent optional source is invalid caller input.
        #expect(absent.prepare(.psql).plain == "FROM ")
    }

    private func expectSiblingAndNested(
        _ sibling: SwifQLable,
        _ nested: SwifQLable,
        dialect: SQLDialect,
        expectedPlain: String,
        expectedQuery: String,
        expectedValues: [String]
    ) {
        let siblingPrepared = sibling.prepare(dialect)
        let nestedPrepared = nested.prepare(dialect)

        #expect(siblingPrepared.plain == expectedPlain)
        #expect(nestedPrepared.plain == expectedPlain)
        #expect(siblingPrepared.splitted.query == expectedQuery)
        #expect(nestedPrepared.splitted.query == expectedQuery)
        #expect(siblingPrepared.splitted.values.map { String(describing: $0) } == expectedValues)
        #expect(nestedPrepared.splitted.values.map { String(describing: $0) } == expectedValues)
        #expect(siblingPrepared.plain == nestedPrepared.plain)
        #expect(siblingPrepared.splitted.query == nestedPrepared.splitted.query)
        #expect(siblingPrepared.splitted.values.map { String(describing: $0) } == nestedPrepared.splitted.values.map { String(describing: $0) })
    }

    @Test("D04-S38 sibling JOIN matches nested SQL and binds on every dialect")
    func s38SiblingJoinMatchesNestedAcrossDialects() {
        let sibling = SwifQL {
            From { Path.Table("User") }
            Join(.left, Path.Table("Profile"))
            On(Path.Table("User").column("id") == 41)
        }
        let nested = SwifQL {
            From {
                Path.Table("User")
                Join(.left, Path.Table("Profile"))
                On(Path.Table("User").column("id") == 41)
            }
        }

        expectSiblingAndNested(
            sibling,
            nested,
            dialect: .psql,
            expectedPlain: #"FROM "User" LEFT JOIN "Profile" ON "User"."id" = 41"#,
            expectedQuery: #"FROM "User" LEFT JOIN "Profile" ON "User"."id" = $1"#,
            expectedValues: ["41"]
        )
        expectSiblingAndNested(
            sibling,
            nested,
            dialect: .mysql,
            expectedPlain: "FROM User LEFT JOIN Profile ON User.id = 41",
            expectedQuery: "FROM User LEFT JOIN Profile ON User.id = ?",
            expectedValues: ["41"]
        )
        expectSiblingAndNested(
            sibling,
            nested,
            dialect: .duck,
            expectedPlain: #"FROM "User" LEFT JOIN "Profile" ON "User"."id" = 41"#,
            expectedQuery: #"FROM "User" LEFT JOIN "Profile" ON "User"."id" = $1"#,
            expectedValues: ["41"]
        )
    }

    @Test("D04-S39 concrete guaranteed From carries two sibling JOINs and alias owners")
    func s39ConcreteFromWithMultipleSiblingJoins() {
        let from = From { Path.Table("User") }
        let guaranteed: FromBuilder.GuaranteedResult = from
        let sibling = SwifQL {
            from
            Join(.left, Path.Table("Profile")).as("profile")
            On(true)
            Join(.inner, Path.Table("Organization"))
            Using("id")
            As("organizationKeys")
        }
        let nested = SwifQL {
            From {
                Path.Table("User")
                Join(.left, Path.Table("Profile")).as("profile")
                On(true)
                Join(.inner, Path.Table("Organization"))
                Using("id")
                As("organizationKeys")
            }
        }
        let expectedPsql = #"FROM "User" LEFT JOIN "Profile" AS "profile" ON TRUE INNER JOIN "Organization" USING ("id") AS "organizationKeys""#
        let expectedMysql = "FROM User LEFT JOIN Profile AS profile ON TRUE INNER JOIN Organization USING (id) AS organizationKeys"

        expectSiblingAndNested(sibling, nested, dialect: .psql, expectedPlain: expectedPsql, expectedQuery: expectedPsql, expectedValues: [])
        expectSiblingAndNested(sibling, nested, dialect: .mysql, expectedPlain: expectedMysql, expectedQuery: expectedMysql, expectedValues: [])
        expectSiblingAndNested(sibling, nested, dialect: .duck, expectedPlain: expectedPsql, expectedQuery: expectedPsql, expectedValues: [])
        #expect(guaranteed.prepare(.psql).plain == #"FROM "User""#)
    }

    @Test("D04-S40 explicit legacy Result variables and helpers remain completed FROM clauses")
    func s40ExplicitLegacyResultCompatibility() {
        let standalone: FromBuilder.Result = From { Path.Table("User") }
        func helper() -> FromBuilder.Result {
            From { Path.Table("Profile") }
        }

        #expect(standalone.prepare(.psql).plain == #"FROM "User""#)
        #expect(helper().prepare(.psql).plain == #"FROM "Profile""#)
    }

    @Test("D04-S41 maybe-empty FROM bodies remain legacy completed clauses")
    func s41NoGuaranteeFromBodiesRemainLegacy() {
        let includeUser = true
        let omitUser = false
        let loopOnly: FromBuilder.Result = From {
            for name in ["User", "Profile"] {
                Path.Table(name)
            }
        }
        let optionalPresent: FromBuilder.Result = From {
            if includeUser {
                Path.Table("User")
            }
        }
        let optionalEmpty: FromBuilder.Result = From {
            if omitUser {
                Path.Table("User")
            }
        }
        let emptyLoop: FromBuilder.Result = From {
            for name in [String]() {
                Path.Table(name)
            }
        }

        #expect(loopOnly.prepare(.psql).plain == #"FROM "User", "Profile""#)
        #expect(optionalPresent.prepare(.psql).plain == #"FROM "User""#)
        #expect(optionalEmpty.prepare(.psql).plain == "FROM ")
        #expect(emptyLoop.prepare(.psql).plain == "FROM ")

        let includeProfile = true
        let names = ["Profile"]
        let optionalThenGuaranteed = From {
            if includeProfile {
                Path.Table("Profile")
            }
            Path.Table("User")
        }
        let loopThenGuaranteed = From {
            for name in names {
                Path.Table(name)
            }
            Path.Table("User")
        }
        let optionalSibling = SwifQL {
            optionalThenGuaranteed
            Join(.left, Path.Table("Account"))
            On(true)
        }
        let optionalNested = SwifQL {
            From {
                if includeProfile { Path.Table("Profile") }
                Path.Table("User")
                Join(.left, Path.Table("Account"))
                On(true)
            }
        }
        let loopSibling = SwifQL {
            loopThenGuaranteed
            Join(.left, Path.Table("Account"))
            On(true)
        }
        let loopNested = SwifQL {
            From {
                for name in names { Path.Table(name) }
                Path.Table("User")
                Join(.left, Path.Table("Account"))
                On(true)
            }
        }
        let expected = #"FROM "Profile", "User" LEFT JOIN "Account" ON TRUE"#
        let expectedMysql = "FROM Profile, User LEFT JOIN Account ON TRUE"
        let dialectExpectations: [(SQLDialect, String)] = [
            (.psql, expected),
            (.mysql, expectedMysql),
            (.duck, expected)
        ]
        for (dialect, expectedDialect) in dialectExpectations {
            expectSiblingAndNested(optionalSibling, optionalNested, dialect: dialect, expectedPlain: expectedDialect, expectedQuery: expectedDialect, expectedValues: [])
            expectSiblingAndNested(loopSibling, loopNested, dialect: dialect, expectedPlain: expectedDialect, expectedQuery: expectedDialect, expectedValues: [])
        }
    }

    @Test("D04-S42 nested S11-S14 FROM bridge keeps exact dialect SQL")
    func s42NestedFromBridgeCompatibilityAcrossDialects() {
        let nestedSelectAlias = From {
            Select { Path.Table("Order").column("userId") }
            From { Path.Table("Order") }
            As("orders")
        }
        let nestedThenSource = From {
            Select { Path.Table("Order").column("id") }
            From { Path.Table("Order") }
            Path.Table("Organization")
        }
        let conditionalNested = From {
            if true {
                Select { Path.Table("Order").column("userId") }
                From { Path.Table("Order") }
                As("orders")
            }
            Path.Table("Organization")
        }
        let explicitRoot = SwifQL {
            Select { Path.Table("Order").column("id") }
            From { Path.Table("Order") }
        }
        let explicitRootSource = From { explicitRoot; As("orders") }

        let psql = [
            #"FROM (SELECT "Order"."userId" FROM "Order") AS "orders""#,
            #"FROM (SELECT "Order"."id" FROM "Order"), "Organization""#,
            #"FROM (SELECT "Order"."userId" FROM "Order") AS "orders", "Organization""#,
            #"FROM (SELECT "Order"."id" FROM "Order") AS "orders""#
        ]
        let mysql = [
            "FROM (SELECT Order.userId FROM Order) AS orders",
            "FROM (SELECT Order.id FROM Order), Organization",
            "FROM (SELECT Order.userId FROM Order) AS orders, Organization",
            "FROM (SELECT Order.id FROM Order) AS orders"
        ]
        let queries: [SwifQLable] = [nestedSelectAlias, nestedThenSource, conditionalNested, explicitRootSource]

        for index in queries.indices {
            let query = queries[index]
            let expectedPsql = psql[index]
            let expectedMysql = mysql[index]
            #expect(query.prepare(.psql).plain == expectedPsql)
            #expect(query.prepare(.psql).splitted.query == expectedPsql)
            #expect(query.prepare(.psql).splitted.values.isEmpty)
            #expect(query.prepare(.mysql).plain == expectedMysql)
            #expect(query.prepare(.mysql).splitted.query == expectedMysql)
            #expect(query.prepare(.mysql).splitted.values.isEmpty)
            #expect(query.prepare(.duck).plain == expectedPsql)
            #expect(query.prepare(.duck).splitted.query == expectedPsql)
            #expect(query.prepare(.duck).splitted.values.isEmpty)
        }
    }

    @Test("D04-S43 later SELECT closes sibling JOIN ownership")
    func s43LaterSelectClosesSiblingJoinOwnership() {
        let sibling = SwifQL {
            Select { Path.Table("User").column("id") }
            From { Path.Table("User") }
            Join(.left, Path.Table("Profile"))
            On(true)
            Select { Path.Table("User").column("name") }
        }
        let nested = SwifQL {
            Select { Path.Table("User").column("id") }
            From {
                Path.Table("User")
                Join(.left, Path.Table("Profile"))
                On(true)
            }
            Select { Path.Table("User").column("name") }
        }
        let psql = #"SELECT "User"."id" FROM "User" LEFT JOIN "Profile" ON TRUE SELECT "User"."name""#
        let mysql = "SELECT User.id FROM User LEFT JOIN Profile ON TRUE SELECT User.name"

        expectSiblingAndNested(sibling, nested, dialect: .psql, expectedPlain: psql, expectedQuery: psql, expectedValues: [])
        expectSiblingAndNested(sibling, nested, dialect: .mysql, expectedPlain: mysql, expectedQuery: mysql, expectedValues: [])
        expectSiblingAndNested(sibling, nested, dialect: .duck, expectedPlain: psql, expectedQuery: psql, expectedValues: [])
        #expect(sibling.prepare(.psql).plain.components(separatedBy: " FROM ").count - 1 == 1)
        #expect(sibling.prepare(.psql).plain.components(separatedBy: " JOIN ").count - 1 == 1)
    }
}
