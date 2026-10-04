import Foundation
import Testing
@testable import SQL

private final class PatternLegacyDialect: SQLDialect {
    override var id: String? { "pattern-legacy" }

    override func bindKey(_ index: Int) -> String {
        ":\(index)"
    }
}

private final class PatternOptInDialect: SQLDialect {
    override var id: String? { "pattern-opt-in" }

    override func bindKey(_ index: Int) -> String {
        ":\(index)"
    }

    override func stringValue(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "''"))'"
    }

    override func inlineUnsafeValue(
        _ value: Encodable,
        context: SwifQLRenderContext
    ) -> String? {
        guard context.contains(.starPattern) else { return nil }
        return "future_inline(\(safeValue(value)))"
    }
}

@Suite("Duck star and COLUMNS tests")
struct DuckStarColumnsTests: SwifQLTests {
    private let events = Path.Table("events")

    private func currentParts(of expression: SwifQLable) -> [SwifQLPart] {
        (expression.parts.first as? SwifQLStructuralFramePart)?.children ?? expression.parts
    }

    @Test("Historical stars, aliases, LIKE, and RENAME property stay exact")
    func historicalStarCompatibility() {
        let value = events.column("value")
        let alias = value => "value_alias"

        check(
            SwifQL.asterisk,
            .psql("*"),
            .mysql("*")
        )
        check(
            (events.*),
            .psql(#""events".* "#),
            .mysql("events.* ")
        )
        check(
            SwifQL.asterisk.like("pattern"),
            .psql("* LIKE 'pattern'"),
            .mysql("* LIKE 'pattern'")
        )
        check(
            SwifQL.asterisk.notLike("pattern"),
            .psql("* NOT LIKE 'pattern'"),
            .mysql("* NOT LIKE 'pattern'")
        )
        check(
            alias,
            .psql(#""events"."value" as "value_alias""#),
            .mysql("events.value as value_alias")
        )
        check(
            SwifQL.asterisk.rename,
            .psql("* RENAME"),
            .mysql("* RENAME")
        )
    }

    @Test("EXCLUDE uses structural last-path names without binds")
    func exclude() {
        let single = SwifQL.asterisk.exclude(events.column("secret"))
        let query = SwifQL.asterisk.exclude(
            events.column("secret"),
            Path.Column("select"),
            Path.Column("имя"),
            Path.Column("a\"b")
        )

        #expect(
            single.prepare(.duck).plain == #"* EXCLUDE ("secret")"#
        )
        #expect(
            query.prepare(.duck).plain ==
                #"* EXCLUDE ("secret", "select", "имя", "a""b")"#
        )
        #expect(query.prepare(.duck).splitted.values.isEmpty)

        let stored: SwifQLable = query
        let copied = SwifQLableParts(parts: stored.parts)
        #expect(copied.prepare(.duck).plain == query.prepare(.duck).plain)

        let structural = currentParts(of: query).compactMap { $0 as? SwifQLStarExcludePart }.last
        #expect(structural?.columnNames == ["secret", "select", "имя", "a\"b"])
    }

    @Test("REPLACE keeps expression parts and target names distinct")
    func replace() {
        let single = SwifQL.asterisk.replace(StarReplacement(1, as: "value"))
        let replacement = SwifQL.asterisk.replace(
            StarReplacement(Fn.coalesce("fallback", events.column("amount")), as: events.column("amount")),
            StarReplacement(1, as: "select")
        )
        let query = SwifQL.select(replacement).from(events)
        let prepared = query.prepare(.duck)

        #expect(single.prepare(.duck).plain == #"* REPLACE (1 as "value")"#)

        #expect(
            prepared.plain ==
                #"SELECT * REPLACE (coalesce('fallback',"events"."amount") as "amount", 1 as "select") FROM "events""#
        )
        #expect(
            prepared.splitted.query ==
                #"SELECT * REPLACE (coalesce($1,"events"."amount") as "amount", $2 as "select") FROM "events""#
        )
        #expect(prepared.splitted.values[0] as? String == "fallback")
        #expect(prepared.splitted.values[1] as? Int == 1)

        let structural = currentParts(of: replacement).compactMap { $0 as? SwifQLStarReplacePart }.last
        #expect(structural?.entries.count == 2)
        #expect(structural?.entries.map(\.columnName) == ["amount", "select"])
        #expect(structural?.entries[0].expressionParts.isEmpty == false)
    }

    @Test("RENAME safely quotes old and new structural names")
    func rename() {
        let single = SwifQL.asterisk.rename(StarRename("value", to: "renamed"))
        let query = SwifQL.asterisk.rename(
            StarRename(events.column("a\"b"), to: "select"),
            StarRename("имя", to: "new\"name")
        )

        #expect(
            single.prepare(.duck).plain == #"* RENAME ("value" as "renamed")"#
        )
        #expect(
            query.prepare(.duck).plain ==
                #"* RENAME ("a""b" as "select", "имя" as "new""name")"#
        )
        #expect(query.prepare(.duck).splitted.values.isEmpty)

        let structural = currentParts(of: query).compactMap { $0 as? SwifQLStarRenamePart }.last
        #expect(structural?.entries.map(\.oldColumnName) == ["a\"b", "имя"])
        #expect(structural?.entries.map(\.newColumnName) == ["select", "new\"name"])
    }

    @Test("GLOB and SIMILAR variants use safe native constants")
    func patterns() {
        let glob = SwifQL.asterisk.glob("metric*")
        let similar = SwifQL.asterisk.similarTo("metric.*")
        let notSimilar = SwifQL.asterisk.notSimilarTo("metric.*")

        #expect(glob.prepare(.duck).plain == "* GLOB 'metric*'")
        #expect(similar.prepare(.duck).plain == "* SIMILAR TO 'metric.*'")
        #expect(notSimilar.prepare(.duck).plain == "* NOT SIMILAR TO 'metric.*'")
        #expect(glob.prepare(.duck).splitted.values.isEmpty)
        #expect(similar.prepare(.duck).splitted.values.isEmpty)
        #expect(notSimilar.prepare(.duck).splitted.values.isEmpty)

        #expect(SwifQL.asterisk.glob("O'Reilly").prepare(.duck).plain == "* GLOB 'O''Reilly'")
    }

    @Test("Ordinary pattern operators keep dynamic values bound")
    func ordinaryPatternOperators() {
        let pattern = "O'Reilly%"
        let column = events.column("metric")

        let glob = column.glob(pattern).prepare(.duck).splitted
        #expect(glob.query == #""events"."metric" GLOB $1"#)
        #expect(glob.values[0] as? String == pattern)

        let similar = column.similarTo(pattern).prepare(.duck).splitted
        #expect(similar.query == #""events"."metric" SIMILAR TO $1"#)
        #expect(similar.values[0] as? String == pattern)

        let notSimilar = column.notSimilarTo(pattern).prepare(.duck).splitted
        #expect(notSimilar.query == #""events"."metric" NOT SIMILAR TO $1"#)
        #expect(notSimilar.values[0] as? String == pattern)

        let psqlSimilar = column.similarTo(pattern).prepare(.psql).splitted
        #expect(psqlSimilar.query == #""events"."metric" SIMILAR TO $1"#)
        #expect(psqlSimilar.values[0] as? String == pattern)

        let psqlNotSimilar = column.notSimilarTo(pattern).prepare(.psql).splitted
        #expect(psqlNotSimilar.query == #""events"."metric" NOT SIMILAR TO $1"#)
        #expect(psqlNotSimilar.values[0] as? String == pattern)
    }

    @Test("Default and opt-in custom dialects use the open contextual hook")
    func customDialectPatternPolicies() {
        let pattern = "O'Reilly%"
        let legacyStar = SwifQL.asterisk.glob(pattern).prepare(PatternLegacyDialect()).splitted
        #expect(legacyStar.query == "* GLOB :1")
        #expect(legacyStar.values[0] as? String == pattern)

        let ordinary = SwifQLableParts(parts: SwifQLPartColumn("metric"))
        let legacyOrdinary = ordinary.glob(pattern).prepare(PatternLegacyDialect()).splitted
        #expect(legacyOrdinary.query == "metric GLOB :1")
        #expect(legacyOrdinary.values[0] as? String == pattern)

        let optInStar = SwifQL.asterisk.glob(pattern).prepare(PatternOptInDialect()).splitted
        #expect(optInStar.query == "* GLOB future_inline('O''Reilly%')")
        #expect(optInStar.values.isEmpty)

        let optInOrdinary = ordinary.glob(pattern).prepare(PatternOptInDialect()).splitted
        #expect(optInOrdinary.query == "metric GLOB :1")
        #expect(optInOrdinary.values[0] as? String == pattern)
    }

    @Test("Star LIKE and NOT LIKE use Duck constants without changing other dialects")
    func starPatternBindingBoundary() {
        let pattern = "O'Reilly%"
        let expectedLike = "* LIKE 'O''Reilly%'"
        let expectedNotLike = "* NOT LIKE 'O''Reilly%'"

        let like = SwifQL.asterisk.like(pattern).prepare(.duck)
        let notLike = SwifQL.asterisk.notLike(pattern).prepare(.duck)

        #expect(like.plain == expectedLike)
        #expect(like.splitted.query == expectedLike)
        #expect(like.splitted.values.isEmpty)
        #expect(notLike.plain == expectedNotLike)
        #expect(notLike.splitted.query == expectedNotLike)
        #expect(notLike.splitted.values.isEmpty)

        let psqlLike = SwifQL.asterisk.like(pattern).prepare(.psql).splitted
        let psqlNotLike = SwifQL.asterisk.notLike(pattern).prepare(.psql).splitted
        #expect(psqlLike.query == "* LIKE $1")
        #expect(psqlLike.values[0] as? String == pattern)
        #expect(psqlNotLike.query == "* NOT LIKE $1")
        #expect(psqlNotLike.values[0] as? String == pattern)

        let mysqlLike = SwifQL.asterisk.like(pattern).prepare(.mysql).splitted
        let mysqlNotLike = SwifQL.asterisk.notLike(pattern).prepare(.mysql).splitted
        #expect(mysqlLike.query == "* LIKE ?")
        #expect(mysqlLike.values[0] as? String == pattern)
        #expect(mysqlNotLike.query == "* NOT LIKE ?")
        #expect(mysqlNotLike.values[0] as? String == pattern)
    }

    @Test("Star semantic ownership survives erasure helpers copies and nesting")
    func starPatternComposition() {
        let pattern = "metric%"
        let expectedLike = "* LIKE 'metric%'"
        let expectedNotLike = "* NOT LIKE 'metric%'"

        let direct = SwifQL.asterisk.like(pattern).prepare(.duck).splitted
        #expect(direct.query == expectedLike)
        #expect(direct.values.isEmpty)

        var erased: SwifQLable = SwifQL.asterisk
        erased = erased.like(pattern)
        #expect(erased.prepare(.duck).splitted.query == expectedLike)
        #expect(erased.prepare(.duck).splitted.values.isEmpty)

        func star() -> SwifQLable { SwifQL.asterisk }
        #expect(star().notLike(pattern).prepare(.duck).splitted.query == expectedNotLike)
        #expect(star().notLike(pattern).prepare(.duck).splitted.values.isEmpty)

        let copied = SwifQLableParts(parts: SwifQL.asterisk.parts)
        #expect(copied.like(pattern).prepare(.duck).splitted.query == expectedLike)
        #expect(copied.like(pattern).prepare(.duck).splitted.values.isEmpty)

        let nested = Fn.columns(SwifQL.asterisk.like(pattern)).prepare(.duck)
        #expect(nested.plain == "COLUMNS(* LIKE 'metric%')")
        #expect(nested.splitted.query == nested.plain)
        #expect(nested.splitted.values.isEmpty)
    }

    @Test("Raw star text without semantic ownership remains ordinary")
    func rawStarBinding() {
        #expect(
            SwifQLPartOperator("*") ==
                SwifQLPartOperator("*", semanticRole: .starProjection)
        )

        let rawStar = SwifQLableParts(parts: SwifQLPartOperator("*"))
        let like = rawStar.like("metric%").prepare(.duck).splitted
        let notLike = rawStar.notLike("metric%").prepare(.duck).splitted

        #expect(like.query == "* LIKE $1")
        #expect(like.values[0] as? String == "metric%")
        #expect(notLike.query == "* NOT LIKE $1")
        #expect(notLike.values[0] as? String == "metric%")
    }

    @Test("Semantic roles are public value-semantic extension points")
    func semanticRoleExtensionSurface() {
        #expect(SwifQLSemanticRole.starProjection.namespace == "swifql")
        #expect(SwifQLSemanticRole.starProjection.name == "starProjection")

        let customRole = SwifQLSemanticRole(
            namespace: "com.example",
            name: "customRole"
        )
        let copiedRole = SwifQLSemanticRole(
            namespace: customRole.namespace,
            name: customRole.name
        )
        #expect(customRole == copiedRole)
        #expect(Set([customRole, copiedRole]).count == 1)

        let historical = SwifQLPartOperator(".*")
        let roleBearing = SwifQLPartOperator(".*", semanticRole: customRole)
        #expect(historical.semanticRole == nil)
        #expect(roleBearing.semanticRole == customRole)
        #expect(historical == roleBearing)

        let copiedOperator = SwifQLableParts(parts: roleBearing.parts)
            .parts
            .compactMap { $0 as? SwifQLPartOperator }
            .last
        #expect(copiedOperator?.semanticRole == customRole)

        let starExclude = currentParts(of: SwifQL.asterisk.exclude("secret"))
            .compactMap { $0 as? SwifQLStarExcludePart }
            .last
        let starReplace = currentParts(
            of: SwifQL.asterisk.replace(StarReplacement(1, as: "value"))
        )
        .compactMap { $0 as? SwifQLStarReplacePart }
        .last
        let starRename = currentParts(
            of: SwifQL.asterisk.rename(StarRename("value", to: "renamed"))
        )
        .compactMap { $0 as? SwifQLStarRenamePart }
        .last

        #expect(starExclude?.semanticRole == .starProjection)
        #expect(starReplace?.semanticRole == .starProjection)
        #expect(starRename?.semanticRole == .starProjection)

        let ordinaryExclude = currentParts(of: events.column("metric").exclude("secret"))
            .compactMap { $0 as? SwifQLStarExcludePart }
            .last
        let ordinaryReplace = currentParts(
            of: events.column("metric").replace(StarReplacement(1, as: "value"))
        )
        .compactMap { $0 as? SwifQLStarReplacePart }
        .last
        let ordinaryRename = currentParts(
            of: events.column("metric").rename(StarRename("value", to: "renamed"))
        )
        .compactMap { $0 as? SwifQLStarRenamePart }
        .last

        #expect(ordinaryExclude?.semanticRole == nil)
        #expect(ordinaryReplace?.semanticRole == nil)
        #expect(ordinaryRename?.semanticRole == nil)
    }

    @Test("Nested projection roles do not leak to outer pattern operators")
    func nestedRoleDoesNotLeak() {
        let pattern = "metric%"
        let nested = Fn.columns(SwifQL.asterisk).like(pattern).prepare(.duck).splitted

        #expect(nested.query == "COLUMNS(*) LIKE $1")
        #expect(nested.values.count == 1)
        #expect(nested.values[0] as? String == pattern)
    }

    @Test("Flat qualified projection roles do not leak through function bodies")
    func flatQualifiedRoleDoesNotLeak() {
        let pattern = "metric%"
        let qualified = events.*
        let modelQualified = CarBrands.self*
        let receivers: [SwifQLable] = [
            Fn.columns(qualified),
            Fn.columns(modelQualified),
            Fn.build(.custom("WRAP"), body: qualified.parts),
            Fn.columns(qualified.exclude("secret"))
        ]

        for receiver in receivers {
            let prepared = receiver.like(pattern).prepare(.duck).splitted
            #expect(prepared.values.count == 1)
            #expect(prepared.values[0] as? String == pattern)
        }

        #expect(qualified.like(pattern).prepare(.duck).splitted.values.isEmpty)
        #expect(modelQualified.like(pattern).prepare(.duck).splitted.values.isEmpty)

        var rawParts = events.parts
        rawParts.append(SwifQLPartOperator(".*"))
        rawParts.append(SwifQLPartOperator(" "))
        let raw = SwifQLableParts(parts: rawParts).like(pattern).prepare(.duck).splitted
        #expect(raw.values.count == 1)
        #expect(raw.values[0] as? String == pattern)
    }

    @Test("Qualified projection stars retain their semantic role")
    func qualifiedProjectionStars() {
        let pattern = "metric%"
        let stars: [SwifQLable] = [events.*, CarBrands.table.*]

        for star in stars {
            let copied = SwifQLableParts(parts: star.parts)
            let originalPSQL = star.prepare(.psql).plain
            let copiedPSQL = copied.prepare(.psql).plain
            let originalMySQL = star.prepare(.mysql).plain
            let copiedMySQL = copied.prepare(.mysql).plain
            #expect(copiedPSQL == originalPSQL)
            #expect(copiedMySQL == originalMySQL)

            let patterned = star.like(pattern).prepare(.duck).splitted
            #expect(patterned.values.isEmpty)
        }
    }

    @Test("Star modifiers preserve direct projection ownership")
    func starModifierOwnership() {
        let pattern = "metric%"
        let modifiedStars: [SwifQLable] = [
            SwifQL.asterisk.exclude("secret"),
            SwifQL.asterisk.replace(StarReplacement(1, as: "value")),
            SwifQL.asterisk.rename(StarRename("value", to: "renamed"))
        ]

        for (index, star) in modifiedStars.enumerated() {
            let prepared = star.like(pattern).prepare(.duck).splitted
            if index == 1 {
                #expect(prepared.values.map { $0 as? Int } == [1])
            } else {
                #expect(prepared.values.isEmpty)
            }
        }


        let filtered = SwifQL.asterisk
            .exclude("secret")
            .like(pattern)
            .prepare(.duck)
            .splitted
        #expect(filtered.query == #"* EXCLUDE ("secret") LIKE 'metric%'"#)
        #expect(filtered.values.isEmpty)

        let multipleModifiers = SwifQL.asterisk
            .exclude("secret")
            .rename(StarRename("value", to: "renamed"))
        #expect(multipleModifiers.ownsStarProjectionSemanticRole)

        func modifiedStar() -> SwifQLable {
            SwifQL.asterisk.exclude("secret")
        }
        var erased: SwifQLable = modifiedStar()
        let copied = SwifQLableParts(parts: erased.parts)
        erased = erased.like(pattern)
        #expect(erased.prepare(.duck).splitted.values.isEmpty)
        #expect(copied.like(pattern).prepare(.duck).splitted.values.isEmpty)

        let ordinary = events.column("metric")
            .exclude("secret")
            .like(pattern)
            .prepare(.duck)
            .splitted
        #expect(ordinary.values.count == 1)
        #expect(ordinary.values[0] as? String == pattern)
    }

    @Test("Ordinary Duck LIKE and NOT LIKE remain bound")
    func ordinaryPatternBinding() {
        let column = events.column("metric")
        let like = column.like("metric%").prepare(.duck).splitted
        let notLike = column.notLike("metric%").prepare(.duck).splitted

        #expect(like.query == #""events"."metric" LIKE $1"#)
        #expect(like.values[0] as? String == "metric%")
        #expect(notLike.query == #""events"."metric" NOT LIKE $1"#)
        #expect(notLike.values[0] as? String == "metric%")
    }

    @Test("COLUMNS accepts a star and composed star modifiers")
    func columnsStar() {
        #expect(Fn.columns(SwifQL.asterisk).prepare(.duck).plain == "COLUMNS(*)")

        let composed = Fn.columns(SwifQL.asterisk.exclude(events.column("secret")))
        #expect(composed.prepare(.duck).plain == #"COLUMNS(* EXCLUDE ("secret"))"#)
        #expect(composed.prepare(.duck).splitted.values.isEmpty)

        let copied = SwifQLableParts(parts: composed.parts)
        #expect(copied.prepare(.duck).plain == composed.prepare(.duck).plain)
    }

    @Test("COLUMNS regex values bind normally, including special content")
    func columnsRegex() {
        let pattern = #"^(O'Reilly|имя|a\b)$"#
        let query = Fn.columns(regex: pattern)
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == #"COLUMNS('^(O''Reilly|имя|a\b)$')"#)
        #expect(prepared.splitted.query == "COLUMNS($1)")
        #expect(prepared.splitted.values[0] as? String == pattern)
    }

    @Test("COLUMNS names use native structural string-list syntax without binds")
    func columnsNames() {
        let query = Fn.columns(
            names: Path.Schema("analytics").table("events").column("metric_b"),
            events.column("metric_a")
        )
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == "COLUMNS(['metric_b', 'metric_a'])")
        #expect(prepared.splitted.query == prepared.plain)
        #expect(prepared.splitted.values.isEmpty)

        let special = Fn.columns(names: "select", "имя", "a\"b", "O'Reilly")
        #expect(
            special.prepare(.duck).plain ==
                "COLUMNS(['select', 'имя', 'a\"b', 'O''Reilly'])"
        )
        #expect(special.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("COLUMNS lambda reuses SQLLambda and preserves body bind order")
    func columnsLambda() {
        let pattern = "metric%"
        let lambda = SQLLambda("c") { c in c.like(pattern) }
        let query = Fn.columns(lambda: lambda)
        let prepared = query.prepare(.duck)

        #expect(
            prepared.plain ==
                #"COLUMNS(lambda "c" : "c" LIKE 'metric%')"#
        )
        #expect(
            prepared.splitted.query ==
                #"COLUMNS(lambda "c" : "c" LIKE $1)"#
        )
        #expect(prepared.splitted.values.count == 1)
        #expect(prepared.splitted.values[0] as? String == pattern)
        #expect(!prepared.plain.contains("->"))
    }

    @Test("UNPACK preserves exact function identity around COLUMNS")
    func unpack() {
        let query = Fn.unpack(Fn.columns(SwifQL.asterisk))

        #expect(query.prepare(.duck).plain == "UNPACK(COLUMNS(*))")
        #expect(query.prepare(.duck).splitted.values.isEmpty)
    }

    @Test("New grammar remains mechanical under PostgreSQL and MySQL")
    func mechanicalOtherDialects() {
        let query = SwifQL.asterisk
            .glob("metric*")
            .exclude(events.column("secret"))

        #expect(query.prepare(.psql).plain == #"* GLOB 'metric*' EXCLUDE ("secret")"#)
        #expect(query.prepare(.mysql).plain == "* GLOB 'metric*' EXCLUDE (secret)")

        let qualified = events.*
            .exclude("secret")
            .rename(StarRename("value", to: "renamed"))
        #expect(
            qualified.prepare(.duck).plain ==
                #""events".* EXCLUDE ("secret") RENAME ("value" as "renamed")"#
        )
    }
}
