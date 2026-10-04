import Foundation
import Testing
@testable import SQL

private final class BigQuerySamplingDialect: SQLDialect {
    override func bindKey(_ i: Int) -> String { "$\(i)" }

    override func sampling(_ sample: SwifQLPartSampling) -> [SwifQLPart] {
        guard sample.construct == .tableSample,
              let first = sample.arguments.first else {
            return super.sampling(sample)
        }

        var parts: [SwifQLPart] = [
            SwifQLPartOperator("TABLESAMPLE"),
            SwifQLPartOperator.space,
            SwifQLPartOperator("SYSTEM"),
            SwifQLPartOperator.space,
            SwifQLPartOperator.openBracket
        ]
        parts.append(contentsOf: first.value.parts)
        if first.role == .percentage {
            parts.append(o: .space, .custom("PERCENT"))
        }
        parts.append(o: .closeBracket)
        return parts
    }
}

private final class SnowflakeSamplingDialect: SQLDialect {
    override func bindKey(_ i: Int) -> String { "$\(i)" }

    override func sampling(_ sample: SwifQLPartSampling) -> [SwifQLPart] {
        guard sample.construct == .usingSample else {
            return super.sampling(sample)
        }

        var parts: [SwifQLPart] = [
            SwifQLPartOperator.using,
            SwifQLPartOperator.space,
            SwifQLPartOperator("SAMPLE"),
            SwifQLPartOperator.space
        ]
        if let method = sample.method {
            parts.append(contentsOf: method.parts)
        }
        parts.append(o: .openBracket)
        for (index, argument) in sample.arguments.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: argument.value.parts)
            if argument.role == .percentage || argument.role == .rows {
                parts.append(o: .space)
                parts.append(o: .custom(argument.role == .percentage ? "PERCENT" : "ROWS"))
            }
        }
        parts.append(o: .closeBracket)
        if let seed = sample.seed {
            parts.append(o: .space, .custom("SEED"), .space, .openBracket)
            parts.append(contentsOf: seed.value.parts)
            parts.append(o: .closeBracket)
        }
        return parts
    }
}

@Suite("Duck SELECT feature tests")
struct DuckSelectFeatureTests {
    private func expectDuck(_ query: SwifQLable, _ expected: String) {
        #expect(query.prepare(.duck).plain == expected)
    }

    @Test("GROUP BY ALL reuses the existing generic groupBy surface")
    func groupByAllReuse() {
        let table = Path.Table("events")
        let category = table.column("category")
        let amount = table.column("amount")
        let base = SwifQL.select(category, Fn.sum(amount)).from(table)

        let fluent = base.groupBy(SwifQL.all)
        expectDuck(
            fluent,
            #"SELECT "events"."category", sum("events"."amount") FROM "events" GROUP BY ALL"#
        )

        var erased: SwifQLable = base
        erased = erased.groupBy(SwifQL.all)
        let copied = SwifQLableParts(parts: erased.parts)
        expectDuck(copied, fluent.prepare(.duck).plain)

        let frame = copied.parts.first as? SwifQLStructuralFramePart
        let group = frame?.children.compactMap { $0 as? SwifQLGroupByPart }.first
        #expect(group?.owner == nil)
    }

    @Test("GROUPING SETS, ROLLUP, and CUBE are ordinary GROUP BY expressions")
    func groupingExpressions() {
        let table = Path.Table("events")
        let category = table.column("category")
        let region = table.column("region")
        let amount = table.column("amount")

        let sets = GroupingSets([category, region], [category], [])
        let groupingSetsQuery = SwifQL
            .select(category, region, Fn.sum(amount), Fn.groupingId(category, region))
            .from(table)
            .groupBy(sets)

        expectDuck(
            groupingSetsQuery,
            #"SELECT "events"."category", "events"."region", sum("events"."amount"), grouping_id("events"."category", "events"."region") FROM "events" GROUP BY GROUPING SETS (("events"."category", "events"."region"), ("events"."category"), ())"#
        )

        let owner = SwifQLClauseOwner(namespace: "task13", name: "grouping")
        let owned = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner]
        )).groupBy(sets)
        let ownedRoot = owned.parts.first as? SwifQLStructuralFramePart
        let ownedGroup = ownedRoot?.children.compactMap { $0 as? SwifQLGroupByPart }.first
        #expect(ownedGroup?.owner == owner)

        expectDuck(
            SwifQL.select(category, region, Fn.sum(amount))
                .from(table)
                .groupBy(Rollup(category, region)),
            #"SELECT "events"."category", "events"."region", sum("events"."amount") FROM "events" GROUP BY ROLLUP("events"."category", "events"."region")"#
        )

        expectDuck(
            SwifQL.select(category, region, Fn.sum(amount))
                .from(table)
                .groupBy(Cube(category, region)),
            #"SELECT "events"."category", "events"."region", sum("events"."amount") FROM "events" GROUP BY CUBE("events"."category", "events"."region")"#
        )

        func rollupFragment(_ lhs: SwifQLable, _ rhs: SwifQLable) -> SwifQLable {
            Rollup(lhs, rhs)
        }
        var query: SwifQLable = SwifQL.select(category).from(table)
        query = query.groupBy(rollupFragment(category, region))
        query = SwifQLableParts(parts: query.parts)
        expectDuck(
            query,
            #"SELECT "events"."category" FROM "events" GROUP BY ROLLUP("events"."category", "events"."region")"#
        )
    }

    @Test("Grouping ID and count overloads preserve exact function shapes")
    func groupingFunctionsAndCount() {
        let table = Path.Table("events")
        let value = table.column("value")
        let query = SwifQL.select(Fn.count(), Fn.count(value)).from(table)

        let expected = #"SELECT count(), count("events"."value") FROM "events""#
        #expect(query.prepare(.duck).plain == expected)
        #expect(query.prepare(.psql).plain == expected)
        #expect(query.prepare(.mysql).plain == "SELECT count(), count(events.value) FROM events")
    }

    @Test("QUALIFY composes with a real window expression")
    func qualifyWindowComposition() {
        let table = Path.Table("events")
        let category = table.column("category")
        let sequence = table.column("seq")
        let ranked = Fn.rowNumber()
            .over(partitionBy: category, orderBy: .asc(sequence))

        func predicate() -> SwifQLable {
            Path.Column("rn") == 1
        }

        var query: SwifQLable = SwifQL
            .select(category, sequence, ranked => "rn")
            .from(table)
        query = query.qualify(predicate()).orderBy(.asc(category))
        expectDuck(
            query,
            #"SELECT "events"."category", "events"."seq", row_number() OVER (PARTITION BY "events"."category" ORDER BY "events"."seq" ASC) as "rn" FROM "events" QUALIFY "rn" = 1 ORDER BY "events"."category" ASC"#
        )
    }

    @Test("ORDER BY ALL uses the existing owner-bearing order part")
    func allOrderItemReuse() {
        let table = Path.Table("events")
        let category = table.column("category")
        let region = table.column("region")
        let base = SwifQL.select(category, region).from(table)

        expectDuck(
            base.orderBy(SwifQL.all),
            #"SELECT "events"."category", "events"."region" FROM "events" ORDER BY ALL"#
        )
        expectDuck(
            base.orderBy(.desc(SwifQL.all, nulls: .last)),
            #"SELECT "events"."category", "events"."region" FROM "events" ORDER BY ALL DESC NULLS LAST"#
        )
        expectDuck(
            base.orderBy(.asc(SwifQL.all, nulls: .first)),
            #"SELECT "events"."category", "events"."region" FROM "events" ORDER BY ALL ASC NULLS FIRST"#
        )

        let owner = SwifQLClauseOwner(namespace: "task13", name: "select")
        let framed = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.orderBy: owner]
        ))
        let owned = framed.orderBy(SwifQL.all)
        let root = owned.parts.first as? SwifQLStructuralFramePart
        let order = root?.children.compactMap { $0 as? SwifQLOrderByPart }.first
        #expect(order?.owner == owner)
        #expect(order?.items.count == 1)
    }

    @Test("Percentage LIMIT keeps ordinary LIMIT binding and SQL identity")
    func limitPercent() {
        let table = Path.Table("events")
        let value = table.column("value")
        let query = SwifQL.select(value).from(table).limit(percent: 30)
        let prepared = query.prepare(.duck)

        #expect(prepared.plain == #"SELECT "events"."value" FROM "events" LIMIT 30%"#)
        #expect(prepared.splitted.query == #"SELECT "events"."value" FROM "events" LIMIT $1%"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["30"])

        let ordinary = SwifQL.select(value).from(table).limit(30)
        #expect(ordinary.prepare(.duck).plain == #"SELECT "events"."value" FROM "events" LIMIT 30"#)
        #expect(ordinary.prepare(.psql).plain == #"SELECT "events"."value" FROM "events" LIMIT 30"#)
    }

    @Test("USING SAMPLE and TABLESAMPLE use distinct typed SQL shapes")
    func sampling() {
        let table = Path.Table("events")
        let value = table.column("value")
        let using = SwifQL
            .select(value)
            .from(table)
            .usingSample(Sample(SampleSize(percentage: 10), method: .reservoir, seed: 42))
            .orderBy(.asc(value))
            .limit(2)

        expectDuck(
            using,
            #"SELECT "events"."value" FROM "events" USING SAMPLE 10% (reservoir, 42) ORDER BY "events"."value" ASC LIMIT 2"#
        )
        #expect(using.prepare(.duck).splitted.values.map { String(describing: $0) } == ["2"])

        let usingWithoutLimit = SwifQL
            .select(value)
            .from(table)
            .usingSample(Sample(SampleSize(percentage: 10), method: .reservoir, seed: 42))
        #expect(usingWithoutLimit.prepare(.duck).splitted.values.isEmpty)

        expectDuck(
            SwifQL.select(value)
                .from(table)
                .usingSample(Sample(SampleSize(rows: 10))),
            #"SELECT "events"."value" FROM "events" USING SAMPLE 10"#
        )

        let sampledTable = table.tableSample(
            TableSample(SampleSize(percentage: 10), method: .reservoir, repeatable: 42)
        )
        expectDuck(
            SwifQL.select(value).from(sampledTable),
            #"SELECT "events"."value" FROM "events" TABLESAMPLE reservoir(10 PERCENT) REPEATABLE (42)"#
        )
        for method in [SampleMethod.system, .bernoulli] {
            expectDuck(
                SwifQL.select(value).from(
                    table.tableSample(TableSample(SampleSize(rows: 10), method: method))
                ),
                #"SELECT "events"."value" FROM "events" TABLESAMPLE "#
                    + method.name
                    + "(10 ROWS)"
            )
        }
        expectDuck(
            SwifQL.select(value).from(table.tableSample(TableSample(SampleSize(percentage: 10)))),
            #"SELECT "events"."value" FROM "events" TABLESAMPLE (10 PERCENT)"#
        )

        let base = SwifQL.select(value).from(table)
        let composed = base
            .usingSample(Sample(SampleSize(percentage: 10), method: .system, seed: 42))
            .limit(2)
        func helper(_ query: SwifQLable) -> SwifQLable {
            query
                .usingSample(Sample(SampleSize(percentage: 10), method: .system, seed: 42))
                .limit(2)
        }
        let erased: SwifQLable = composed
        let copied = SwifQLableParts(parts: erased.parts)
        var conditional: SwifQLable = base
        if true {
            conditional = conditional
                .usingSample(Sample(SampleSize(percentage: 10), method: .system, seed: 42))
                .limit(2)
        }
        for query in [composed, helper(base), copied, conditional] {
            let prepared = query.prepare(.duck)
            #expect(prepared.plain == composed.prepare(.duck).plain)
            #expect(prepared.splitted.query == composed.prepare(.duck).splitted.query)
            #expect(prepared.splitted.values.map { String(describing: $0) } == ["2"])
        }
    }

    @Test("Sampling values stay open, ordered, and construct-specific")
    func samplingSemanticModel() {
        let expression: SwifQLable = Path.Table("events").column("weight")
        let method = SampleMethod(namespace: "vendor", name: "stratified")
        let arguments = [
            SampleArgument(percentage: expression),
            SampleArgument(7, role: .rows)
        ]
        let using = Sample(
            arguments: arguments,
            method: method,
            seed: expression
        )
        let table = TableSample(
            arguments: arguments,
            method: method,
            repeatable: expression
        )

        #expect(method.name == "stratified")
        #expect(SampleArgumentRole.percentage != SampleArgumentRole.rows)
        #expect(using.arguments.count == 2)
        #expect(using.arguments[0].role == .percentage)
        #expect(using.arguments[1].role == .rows)
        #expect(using.arguments[0].value.prepare(.duck).plain == expression.prepare(.duck).plain)
        #expect(SampleSize(percentage: 0.5).prepare(.duck).splitted.values.count == 1)
        #expect(using.seed?.value.prepare(.duck).plain == expression.prepare(.duck).plain)
        #expect(table.repeatable?.value.prepare(.duck).plain == expression.prepare(.duck).plain)
        #expect(using.prepare(.duck).plain != table.prepare(.duck).plain)
    }

    @Test("Custom dialect sampling policies retain binds and reshape grammar")
    func samplingDialectPolicies() {
        let table = Path.Table("events")
        let value = SwifQLableParts(parts: SwifQLPartOperator("value"))
        let bigQuery = SwifQL
            .select(value)
            .from(table.tableSample(
                TableSample(
                    arguments: [SampleArgument(percentage: 0.5)],
                    method: .system
                )
            ))
        let bigPrepared = bigQuery.prepare(BigQuerySamplingDialect())

        #expect(
            bigPrepared.plain ==
                #"SELECT value FROM events TABLESAMPLE SYSTEM (0.5 PERCENT)"#
        )
        #expect(
            bigPrepared.splitted.query ==
                #"SELECT value FROM events TABLESAMPLE SYSTEM ($1 PERCENT)"#
        )
        #expect(bigPrepared.splitted.values.map { String(describing: $0) } == ["0.5"])

        let method = SampleMethod(namespace: "vendor", name: "stratified")
        let snowflakeQuery = SwifQL
            .select(value)
            .from(table)
            .usingSample(
                Sample(
                    arguments: [
                        SampleArgument(percentage: 0.5),
                        SampleArgument(12, role: .rows)
                    ],
                    method: method,
                    seed: 7
                )
            )
        let snowflakePrepared = snowflakeQuery.prepare(SnowflakeSamplingDialect())

        #expect(
            snowflakePrepared.plain ==
                #"SELECT value FROM events USING SAMPLE stratified(0.5 PERCENT, 12 ROWS) SEED (7)"#
        )
        #expect(
            snowflakePrepared.splitted.query ==
                #"SELECT value FROM events USING SAMPLE stratified($1 PERCENT, $2 ROWS) SEED ($3)"#
        )
        #expect(
            snowflakePrepared.splitted.values.map { String(describing: $0) } ==
                ["0.5", "12", "7"]
        )
    }

    @Test("Existing DISTINCT, FILTER, WINDOW, OFFSET, and FROM-first forms remain exact")
    func existingSelectReuse() {
        let table = Path.Table("events")
        let category = table.column("category")
        let value = table.column("value")

        let distinct = SwifQL.select(Distinct(category)).from(table)
        #expect(distinct.prepare(.duck).plain == #"SELECT DISTINCT "events"."category" FROM "events""#)

        let distinctOn = Distinct(on: category).andAlso(category, value)
        let distinctOnQuery = SwifQL.select(distinctOn).from(table).orderBy(.asc(category))
        #expect(
            distinctOnQuery.prepare(.duck).plain
                == #"SELECT DISTINCT ON ("events"."category") "events"."category", "events"."value" FROM "events" ORDER BY "events"."category" ASC"#
        )

        let filtered = SwifQL.select(Fn.count(value).filter(where: value > 20)).from(table)
        #expect(
            filtered.prepare(.duck).plain
                == #"SELECT count("events"."value") FILTER (WHERE "events"."value" > 20) FROM "events""#
        )

        let windowed = SwifQL.select(
            Fn.rowNumber().over(partitionBy: category, orderBy: .asc(value))
        ).from(table)
        #expect(
            windowed.prepare(.duck).plain
                == #"SELECT row_number() OVER (PARTITION BY "events"."category" ORDER BY "events"."value" ASC) FROM "events""#
        )

        let fromFirst = SwifQL.from(table).select(value).limit(2).offset(1)
        #expect(
            fromFirst.prepare(.duck).plain
                == #"FROM "events" SELECT "events"."value" LIMIT 2 OFFSET 1"#
        )
    }
}
