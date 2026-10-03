import SwifQL
import Testing

private enum Design037RootSuffixEnum: String, Codable {
    case active
}

private struct Design037RootSuffixModel: Decodable {
    let status: Design037RootSuffixEnum
}

private struct Design037RootSuffixUniversalPath: SwifQLable, SwifQLUniversalKeyPath {
    typealias AType = Design037RootSuffixEnum
    typealias AModel = Design037RootSuffixModel
    typealias ARoot = Design037RootSuffixUniversalPath

    var parts: [SwifQLPart] {
        Select { Path.Column("root_column") }.as("probe_suffix").parts
    }

    var path: String { "status" }
    var lastPath: String { "status" }
    var originalKeyPath: KeyPath<Design037RootSuffixModel, Design037RootSuffixEnum> { \.status }
}

private struct Design037RootSuffixArrayElement: SwifQLable {
    let parts: [SwifQLPart]
}

private final class Design037StructuralSuffixScopeDialect: SQLDialect {
    override func keyPath(_ keyPath: SwifQLPartKeyPath) -> String {
        "ordinary"
    }

    override func keyPath(
        _ keyPath: SwifQLPartKeyPath,
        context: SwifQLRenderContext
    ) -> String {
        if context.contains(.simplifiedPivotOn) { return "pivot-on" }
        if context.contains(.simplifiedPivotUsing) { return "pivot-using" }
        if context.contains(.simplifiedPivotGroupBy) { return "pivot-group" }
        if context.contains(.simplifiedPivotOrderBy) { return "pivot-order" }
        if context.contains(.simplifiedUnpivotOrderBy) { return "unpivot-order" }
        return "ordinary"
    }
}

@Suite("DESIGN-037 global root-suffix compatibility")
struct Design037GlobalRootSuffixCompatibilityTests: SwifQLTests {
    private var root: any SwifQLable { Select { Path.Column("id") }.as("suffix") }

    private var base: any SwifQLable {
        Select { Path.Column("root_column") }.as("probe_suffix")
    }

    private func verify(_ cases: [(String, any SwifQLable)]) {
        for (name, value) in cases {
            guard let frame = value.parts.first as? SwifQLStructuralFramePart else {
                Issue.record("\(name): structural root was lost")
                continue
            }
            let root = SwifQLableParts(parts: frame.children).prepare(.psql).plain
            let suffix = SwifQLableParts(parts: Array(value.parts.dropFirst())).prepare(.psql).plain
            #expect(root == #"SELECT "root_column""#, "\(name): root children changed to \(root)")
            #expect(suffix.contains(#"as "probe_suffix""#), "\(name): suffix absent from \(suffix)")
        }
    }

    @Test("Multi-fragment roots keep an aliased statement suffix before later clauses")
    func multiFragmentRootLowering() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("x")
        let single = SwifQL { stored }
        let limited = SwifQL { stored; Limit(1) }
        let filtered = SwifQL { stored; Where { Path.Column("status") == "later" } }

        #expect(single.prepare(.psql).plain == #"SELECT "id" as "x""#)
        #expect(limited.prepare(.psql).plain == #"SELECT "id" as "x" LIMIT 1"#)
        #expect(filtered.prepare(.psql).plain == #"SELECT "id" as "x" WHERE "status" = 'later'"#)
        check(
            limited,
            .psql(#"SELECT "id" as "x" LIMIT 1"#),
            .mysql("SELECT id as x LIMIT 1"),
            .duck(#"SELECT "id" as "x" LIMIT 1"#)
        )

        let statementAndClause = SwifQL { Select { Path.Column("id") }; Limit(1) }
        let ordinaryFragmentAndClause = SwifQL { Path.Column("id"); Limit(1) }
        #expect(statementAndClause.prepare(.psql).plain == #"SELECT "id" LIMIT 1"#)
        #expect(ordinaryFragmentAndClause.prepare(.psql).plain == #""id" LIMIT 1"#)
    }

    @Test("Root lowering preserves set-result suffixes and empty-fragment order")
    func rootFragmentSequence() {
        let first: any SwifQLable = Select { Path.Column("id") }.as("left")
        let second: any SwifQLable = Select { Path.Column("name") }.as("right")
        let empty: any SwifQLable = SwifQLableParts(parts: [])
        let setResult: any SwifQLable = Union([first, second]).as("combined")
        let singleSetRoot = SwifQL { setResult }

        #expect(singleSetRoot.prepare(.psql).plain == setResult.prepare(.psql).plain)
        #expect(SwifQL { first; empty; second }.prepare(.psql).plain == #"SELECT "id" as "left" SELECT "name" as "right""#)
        #expect(SwifQL { setResult; Limit(1) }.prepare(.psql).plain == #"(SELECT "id") as "left" UNION (SELECT "name") as "right" as "combined" LIMIT 1"#)
    }

    @Test("Root lowering keeps statement, suffix, and later bind order")
    func rootBindOrder() {
        let stored: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            Where { Path.Column("inside") == "statement-bind" }
        }.as(Path.Column("suffixTag") == "suffix-bind")
        let query = SwifQL {
            stored
            Where { Path.Column("outside") == "continuation-bind" }
        }
        let prepared = query.prepare(.psql)
        let singlePrepared = SwifQL { stored }.prepare(.psql)

        #expect(singlePrepared.splitted.query == #"SELECT "id" WHERE "inside" = $1 as "suffixTag" = $2"#)
        #expect(singlePrepared.splitted.values.map { String(describing: $0) } == ["statement-bind", "suffix-bind"])
        #expect(prepared.splitted.query == #"SELECT "id" WHERE "inside" = $1 as "suffixTag" = $2 WHERE "outside" = $3"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["statement-bind", "suffix-bind", "continuation-bind"])
    }

    @Test("Closure JOIN nests the root frame and keeps the suffix outside it")
    func closureJoinEmbedding() {
        let stored: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            Where { Path.Column("inside") == "join-statement" }
        }.as(Path.Column("sourceTag") == "join-suffix")
        let query = From {
            Path.Table("Outer")
            Join(.inner) { stored }
            On(Path.Column("enabled") == "join-on")
        }
        let prepared = query.prepare(.psql)

        #expect(prepared.splitted.query == #"FROM "Outer" INNER JOIN (SELECT "id" WHERE "inside" = $1) as "sourceTag" = $2 ON "enabled" = $3"#)
        #expect(prepared.splitted.values.map { String(describing: $0) } == ["join-statement", "join-suffix", "join-on"])

        let left: any SwifQLable = Select { Path.Column("id") }.as("left")
        let right: any SwifQLable = Select { Path.Column("name") }.as("right")
        let setResult: any SwifQLable = Union([left, right]).as("combined")
        let setJoin = From {
            Path.Table("Outer")
            Join(.inner) { setResult }
            On(Path.Column("enabled") == "set-join-on")
        }.prepare(.psql)
        #expect(setJoin.splitted.query == #"FROM "Outer" INNER JOIN ((SELECT "id") as "left" UNION (SELECT "name") as "right") as "combined" ON "enabled" = $1"#)
        #expect(setJoin.splitted.values.map { String(describing: $0) } == ["set-join-on"])
    }

    @Test("Union initializers and binary set operations keep both operands' suffixes")
    func setOperationOperands() {
        let left: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            Where { Path.Column("side") == "left-statement" }
        }.as(Path.Column("leftTag") == "left-suffix")
        let right: any SwifQLable = SwifQL {
            Select { Path.Column("name") }
            Where { Path.Column("side") == "right-statement" }
        }.as(Path.Column("rightTag") == "right-suffix")

        let union = Union([left, right]).prepare(.psql)
        #expect(union.splitted.query == #"(SELECT "id" WHERE "side" = $1) as "leftTag" = $2 UNION (SELECT "name" WHERE "side" = $3) as "rightTag" = $4"#)
        #expect(union.splitted.values.map { String(describing: $0) } == ["left-statement", "left-suffix", "right-statement", "right-suffix"])

        let byName = left.union(byName: right).prepare(.psql)
        #expect(byName.splitted.query == #"(SELECT "id" WHERE "side" = $1) as "leftTag" = $2 UNION BY NAME (SELECT "name" WHERE "side" = $3) as "rightTag" = $4"#)
        #expect(byName.splitted.values.map { String(describing: $0) } == ["left-statement", "left-suffix", "right-statement", "right-suffix"])

        #expect(left.union(right).prepare(.psql).plain == #"(SELECT "id" WHERE "side" = 'left-statement') as "leftTag" = 'left-suffix' UNION (SELECT "name" WHERE "side" = 'right-statement') as "rightTag" = 'right-suffix'"#)
        #expect(left.intersect(right).prepare(.psql).splitted.values.map { String(describing: $0) } == ["left-statement", "left-suffix", "right-statement", "right-suffix"])
        #expect(left.except(right).prepare(.psql).plain.contains(#"(SELECT "id" WHERE "side" = 'left-statement') as "leftTag" = 'left-suffix' EXCEPT"#))
    }

    @Test("WITH keeps suffix-bearing statement values within its query boundary")
    func withInitializerEmbedding() {
        let query: any SwifQLable = SwifQL {
            Select { Path.Column("id") }
            Where { Path.Column("inside") == "cte-statement" }
        }.as(Path.Column("queryTag") == "cte-suffix")
        let cte = With(Path.Table("cte"), query).prepare(.psql)

        #expect(cte.splitted.query == #""cte" as ((SELECT "id" WHERE "inside" = $1) as "queryTag" = $2)"#)
        #expect(cte.splitted.values.map { String(describing: $0) } == ["cte-statement", "cte-suffix"])
        #expect(With(Path.Table("plain_cte"), Select { Path.Column("id") }).prepare(.psql).plain == #""plain_cte" as (SELECT "id")"#)
    }

    @Test("Fluent WITH continuation follows a stored root suffix")
    func withContinuationAfterSuffix() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")
        let continued = stored.with(With(Path.Table("cte"), Select { Path.Column("value") }))

        #expect(continued.prepare(.psql).plain == #"SELECT "id" as "root" WITH "cte" as (SELECT "value")"#)
        #expect(From { continued }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" WITH "cte" as (SELECT "value")"#)
    }

    @Test("Nested statement and set-result values keep chained suffix ownership")
    func nestedAndChainedSuffixes() {
        let statement: any SwifQLable = Select { Path.Column("id") }.as("first").as("second")
        let idQuery: any SwifQLable = Select { Path.Column("id") }
        let nameQuery: any SwifQLable = Select { Path.Column("name") }
        let setResult: any SwifQLable = Union([idQuery, nameQuery]).as("combined").as("final")

        #expect(From { statement }.prepare(.psql).plain == #"FROM (SELECT "id") as "first" as "second""#)
        #expect(Select { statement }.prepare(.psql).plain == #"SELECT (SELECT "id") as "first" as "second""#)
        #expect(From { setResult }.prepare(.psql).plain == #"FROM ((SELECT "id") UNION (SELECT "name")) as "combined" as "final""#)
        #expect(Select { setResult }.prepare(.psql).plain == #"SELECT ((SELECT "id") UNION (SELECT "name")) as "combined" as "final""#)
        #expect(With(Path.Table("cte"), setResult).prepare(.psql).plain == #""cte" as (((SELECT "id") UNION (SELECT "name")) as "combined" as "final")"#)
    }

    @Test("Structural continuations keep prior suffixes before continuation parts")
    func structuralContinuationOrder() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root").as("chained")
        let ordered = stored
            .groupBy(Path.Column("category"))
            .orderBy(.desc(Path.Column("category")))
        let appended = stored.structurallyAppending(
            SwifQLableParts(parts: [SwifQLPartOperator.space, SwifQLPartOperator.custom("TAIL")])
        )
        let emptyAppend = stored.structurallyAppending(SwifQLableParts(parts: []))
        let adjacentAppend = stored.structurallyAppending(
            SwifQLableParts(parts: [SwifQLPartOperator.custom("TAIL")])
        )

        #expect(ordered.prepare(.psql).plain == #"SELECT "id" as "root" as "chained" GROUP BY "category" ORDER BY "category" DESC"#)
        #expect(From { ordered }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" as "chained" GROUP BY "category" ORDER BY "category" DESC"#)
        #expect(appended.prepare(.psql).plain == #"SELECT "id" as "root" as "chained" TAIL"#)
        #expect(From { appended }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" as "chained" TAIL"#)
        #expect(emptyAppend.prepare(.psql).plain == stored.prepare(.psql).plain)
        #expect(adjacentAppend.prepare(.psql).plain == #"SELECT "id" as "root" as "chained"TAIL"#)

        let bareRoot = Select { Path.Column("id") }.structurallyAppending(
            SwifQLableParts(parts: [SwifQLPartOperator.space, SwifQLPartOperator.custom("TAIL")])
        )
        #expect(bareRoot.prepare(.psql).plain == #"SELECT "id" TAIL"#)

        let boundSuffix: any SwifQLable = Select { Path.Column("id") }
            .as(Path.Column("suffixTag") == "suffix-bind")
        let boundWhere = Where { Path.Column("status") == "continuation-bind" }
        let boundContinuation = boundSuffix.structurallyAppending(
            SwifQLableParts(parts: [SwifQLPartOperator.space] + boundWhere.parts)
        ).prepare(.psql)
        #expect(boundContinuation.splitted.query == #"SELECT "id" as "suffixTag" = $1 WHERE "status" = $2"#)
        #expect(boundContinuation.splitted.values.map { String(describing: $0) } == ["suffix-bind", "continuation-bind"])
    }

    @Test("Set-result continuation keeps its suffix and complete operand parts")
    func setResultContinuation() {
        let left: any SwifQLable = Select { Path.Column("id") }.as("left")
        let right: any SwifQLable = Select { Path.Column("name") }.as("right")
        let stored = Union([left, right]).as("combined")
        let appended = stored.structurallyAppending(
            SwifQLableParts(parts: [SwifQLPartOperator.space, SwifQLPartOperator.custom("TAIL")])
        )
        let fluentUnion = left.union
        let rootUnion = SwifQL { fluentUnion; right }

        let plainUnion = Select { Path.Column("plain") }.union
        let singleAliasUnion = Select { Path.Column("single") }.as("one").union
        let chainedAliasUnion = Select { Path.Column("chained") }.as("one").as("two").union

        #expect(appended.prepare(.psql).plain == #"(SELECT "id") as "left" UNION (SELECT "name") as "right" as "combined" TAIL"#)
        #expect(From { stored }.prepare(.psql).plain == #"FROM ((SELECT "id") as "left" UNION (SELECT "name") as "right") as "combined""#)
        #expect(fluentUnion.prepare(.psql).plain == #"SELECT "id" as "left" UNION "#)
        #expect(rootUnion.prepare(.psql).plain == #"SELECT "id" as "left" UNION  SELECT "name" as "right""#)
        #expect(plainUnion.prepare(.psql).plain == #"SELECT "plain" UNION "#)
        #expect(singleAliasUnion.prepare(.psql).plain == #"SELECT "single" as "one" UNION "#)
        #expect(chainedAliasUnion.prepare(.psql).plain == #"SELECT "chained" as "one" as "two" UNION "#)
    }

    @Test("Core fluent clause methods preserve a pre-existing suffix")
    func fluentClauseContinuation() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")
        #expect(stored.limit(2).prepare(.psql).plain == #"SELECT "id" as "root" LIMIT 2"#)
        #expect(stored.offset(3).prepare(.psql).plain == #"SELECT "id" as "root" OFFSET 3"#)
        #expect(stored.where(Path.Column("status") == "active").prepare(.psql).plain == #"SELECT "id" as "root" WHERE "status" = 'active'"#)
        #expect(stored.having(Path.Column("count") > 1).prepare(.psql).plain == #"SELECT "id" as "root" HAVING "count" > 1"#)
        #expect(stored.qualify(Path.Column("rank") > 1).prepare(.psql).plain == #"SELECT "id" as "root" QUALIFY "rank" > 1"#)
        #expect(stored.select(Path.Column("name")).prepare(.psql).plain == #"SELECT "id" as "root" SELECT "name""#)
        #expect(stored.from(Path.Table("source")).prepare(.psql).plain == #"SELECT "id" as "root" FROM "source""#)
        let legacyJoin = stored.join(.inner, Path.Table("source"), on: Path.Column("enabled") == "legacy-join").prepare(.psql)
        #expect(legacyJoin.splitted.query == #"SELECT "id" as "root" INNER JOIN "source" ON "enabled" = $1"#)
        #expect(legacyJoin.splitted.values.map { String(describing: $0) } == ["legacy-join"])
        #expect(From { stored.limit(2) }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" LIMIT 2"#)
        #expect(From { stored.where(Path.Column("status") == "active") }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" WHERE "status" = 'active'"#)
    }

    @Test("DISTINCT, RETURNING, and WINDOW fluents preserve a pre-existing suffix")
    func additionalLegacyClauseContinuations() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")

        #expect(stored.distinct.prepare(.psql).plain == #"SELECT "id" as "root" DISTINCT"#)
        #expect(stored.returning.prepare(.psql).plain == #"SELECT "id" as "root" RETURNING"#)
        #expect(stored.returning(Path.Column("result")).prepare(.psql).plain == #"SELECT "id" as "root" RETURNING "result""#)
        #expect(stored.returning([Path.Column("result")]).prepare(.psql).plain == #"SELECT "id" as "root" RETURNING "result""#)
        #expect(stored.window(Path.Column("w")).prepare(.psql).plain == #"SELECT "id" as "root" WINDOW "w""#)
        #expect(From { stored.distinct }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" DISTINCT"#)
        #expect(From { stored.returning(Path.Column("result")) }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" RETURNING "result""#)
    }

    @Test("EXISTS and USING SAMPLE continuations preserve a pre-existing suffix")
    func additionalSelectClauseContinuations() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")

        #expect(stored.whereExists(Path.Table("present")).prepare(.psql).plain == #"SELECT "id" as "root" WHERE EXISTS ("present")"#)
        #expect(stored.whereNotExists(Path.Table("missing")).prepare(.psql).plain == #"SELECT "id" as "root" WHERE NOT EXISTS ("missing")"#)
        let subquery: any SwifQLable = Select { Path.Column("present") }.as("nested")
        #expect(stored.whereExists(subquery).prepare(.psql).plain == #"SELECT "id" as "root" WHERE EXISTS (SELECT "present" as "nested")"#)
        #expect(stored.usingSample(Sample(SampleSize(rows: 10))).prepare(.duck).plain == #"SELECT "id" as "root" USING SAMPLE 10"#)
        #expect(From { stored.whereExists(Path.Table("present")) }.prepare(.psql).plain == #"FROM (SELECT "id") as "root" WHERE EXISTS ("present")"#)
    }

    @Test("PIVOT continuations retain root owner metadata after an alias suffix")
    func pivotOwnerAndScope() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")
        let pivot = stored.pivot(Path.Table("source"))
        let continued = pivot
            .on(Path.Column("period"), in: "p1")
            .using(Fn.sum(Path.Column("amount")))
            .groupBy(Path.Column("category"))
            .orderBy(.asc(Path.Column("category")))
        let rendered = continued.prepare(Design037StructuralSuffixScopeDialect()).plain

        #expect(pivot.structuralOwner(for: .on) == .simplifiedPivot)
        #expect(pivot.structuralOwner(for: .using) == .simplifiedPivot)
        #expect(pivot.structuralOwner(for: .groupBy) == .simplifiedPivot)
        #expect(pivot.structuralOwner(for: .orderBy) == .simplifiedPivot)
        #expect(continued.prepare(.psql).plain == #"SELECT "id" as "root" PIVOT "source" ON "period" IN ('p1') USING sum("amount") GROUP BY "category" ORDER BY "category" ASC"#)
        #expect(rendered.contains("pivot-on"))
        #expect(rendered.contains("pivot-using"))
        #expect(rendered.contains("pivot-group"))
        #expect(rendered.contains("pivot-order"))
        #expect(From { continued }.prepare(.psql).plain.hasPrefix(#"FROM (SELECT "id") as "root" PIVOT"#))
    }

    @Test("UNPIVOT continuations retain root owner metadata after an alias suffix")
    func unpivotOwnerAndScope() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")
        let unpivot = stored.unpivot(Path.Table("source"))
            .on(Path.Column("jan"), Path.Column("feb"))
            .into(name: Path.Column("month"), value: Path.Column("amount"))
        let ordered = unpivot.orderBy(.asc(Path.Column("month")))
        let rendered = ordered.prepare(Design037StructuralSuffixScopeDialect()).plain

        #expect(unpivot.structuralOwner(for: .orderBy) == .simplifiedUnpivot)
        #expect(ordered.prepare(.psql).plain == #"SELECT "id" as "root" UNPIVOT "source" ON "jan", "feb" INTO NAME "month" VALUE "amount" ORDER BY "month" ASC"#)
        #expect(rendered.contains("unpivot-order"))
        #expect(From { ordered }.prepare(.psql).plain.hasPrefix(#"FROM (SELECT "id") as "root" UNPIVOT"#))
    }

    @Test("Literal tilde overloads preserve suffix order and literal spacing")
    func literalTildeComposition() {
        let stored: any SwifQLable = Select { Path.Column("id") }.as("root")
        let part = stored ~ SwifQLPartOperator.custom("TAIL")
        let value = stored ~ SwifQLableParts(parts: [SwifQLPartOperator.custom("TAIL")])
        let nextRoot: any SwifQLable = Select { Path.Column("name") }.as("next")
        let rootPair = stored ~ nextRoot
        let nonRoot = Path.Column("base") ~ Path.Column("tail")
        let bindBearing = stored ~ (Path.Column("tail") == "tilde-bind")

        #expect(part.prepare(.psql).plain == #"SELECT "id" as "root"TAIL"#)
        #expect(value.prepare(.psql).plain == part.prepare(.psql).plain)
        #expect(rootPair.prepare(.psql).plain == #"SELECT "id" as "root"SELECT "name" as "next""#)
        #expect(nonRoot.prepare(.psql).plain == #""base""tail""#)
        #expect(bindBearing.prepare(.psql).splitted.query == #"SELECT "id" as "root""tail" = $1"#)
        #expect(bindBearing.prepare(.psql).splitted.values.map { String(describing: $0) } == ["tilde-bind"])
    }

    @Test("DML, MERGE, DDL, COPY, ATTACH, type, sequence, index, and macro declarations")
    func targetSpecificContinuations() {
        let target = Path.Table("target")
        let source = Path.Table("source")
        let value = Path.Column("value")
        let cases: [(String, any SwifQLable)] = [
            ("attach", base.attach("memory", options: [])),
            ("detach", base.detach(Path.Catalog("analytics"))),
            ("use catalog", base.use(Path.Catalog("analytics"))),
            ("use schema", base.use(Path.Schema("main"))),
            ("use catalog-schema", base.use(Path.Catalog("analytics").schema("main"))),
            ("copy to", base.copy(target, to: Path.Table("file"), options: [])),
            ("copy from", base.copy(target, from: source, options: [])),
            ("copy query", base.copy(query: Select { value }, to: Path.Table("file"), options: [])),
            ("copy database", base.copy(fromDatabase: Path.Catalog("source"), to: Path.Catalog("destination"), options: [])),
            ("table definitions", base.tableDefinitions([value])),
            ("truncate", base.truncate(target)),
            ("index items", base.indexItems([.column("id")])),
            ("macro parameters", base.macroParameters([MacroParameter("p", .int)])),
            ("merge into", base.merge(into: target)),
            ("merge using columns", base.using(columns: ["id", "name"])),
            ("merge columns variadic", base.using(columns: "id", "name")),
            ("sequence start", base.start(1)),
            ("sequence start with", base.start(with: 2)),
            ("sequence increment", base.increment(by: 3)),
            ("sequence min", base.minValue(4)),
            ("sequence max", base.maxValue(5)),
            ("type", base.type(.text)),
            ("enum", base.enum(["one", "two"])),
            ("enum select", base.enum(select: Select { value })),
            ("keyword or", base.or),
            ("keyword replace", base.replace),
            ("keyword view", base.view),
            ("keyword sequence", base.sequence),
            ("keyword macro", base.macro),
            ("keyword index", base.index),
            ("keyword temp", base.temp),
            ("keyword temporary", base.temporary),
            ("keyword ignore", base.ignore),
            ("keyword name", base.name),
            ("keyword when", base.when),
            ("keyword matched", base.matched),
            ("keyword source", base.source),
            ("keyword target", base.target),
            ("keyword cycle", base.cycle),
            ("keyword minValue", base.minValue),
            ("keyword maxValue", base.maxValue),
            ("keyword data", base.data)
        ]
        verify(cases)
    }

    @Test("Core fluent, DML clause, and transaction declaration continuations")
    func fluentContinuations() {
        let value = Path.Column("value")
        let predicate: any SwifQLable = Path.Column("ready") == true
        let table = Path.Table("target")
        let sample = Sample(SampleSize(rows: 10))
        let tableSample = TableSample(SampleSize(rows: 20))
        let cases: [(String, any SwifQLable)] = [
            ("action", base.action),
            ("add", base.add),
            ("after", base.after),
            ("all", base.all),
            ("alter", base.alter),
            ("and keyword", base.and),
            ("before", base.before),
            ("begin", base.begin),
            ("cascade", base.cascade),
            ("check", base.check),
            ("column", base.column),
            ("commit", base.commit),
            ("conflict keyword", base.conflict),
            ("conflict paths", base.conflict(["id", "name"])),
            ("constraint keyword", base.constraint),
            ("constraint name", base.constraint("constraint_name")),
            ("create", base.create),
            ("default keyword", base.default),
            ("default value", base.default(value)),
            ("delete keyword", base.delete),
            ("delete from", base.delete(from: table)),
            ("distinct", base.distinct),
            ("do", base.do),
            ("drop", base.drop),
            ("end", base.end),
            ("epoch keyword", base.epoch),
            ("epoch expression", base.epoch(with: value)),
            ("filter", base.filter(where: [predicate])),
            ("from", base.from([table])),
            ("fulltext", base.fulltext(value)),
            ("function", base.function),
            ("having", base.having(predicate)),
            ("if", base.if),
            ("insert keyword", base.insert),
            ("into keyword", base.into),
            ("new columns", base.newColumns([NewColumn("id", .int)])),
            ("fields", base.fields([Path.Column("id")])),
            ("table target", base[table: table]),
            ("interval keyword", base.interval),
            ("interval value", base.interval("one day")),
            ("items", base.items([value])),
            ("key", base.key),
            ("limit", base.limit(10)),
            ("limit percent", base.limit(percent: 25)),
            ("no", base.no),
            ("nothing", base.nothing),
            ("null", base.null),
            ("offset", base.offset(5)),
            ("on keyword", base.on),
            ("owner", base.owner),
            ("partition keyword", base.partition),
            ("by keyword", base.by),
            ("partition by", base.partition(by: value)),
            ("primary", base.primary),
            ("qualify", base.qualify(predicate)),
            ("raw", base.raw("TAIL")),
            ("references", base.references),
            ("rename", base.rename),
            ("restrict", base.restrict),
            ("return", base.return),
            ("returning keyword", base.returning),
            ("returning paths", base.returning(["id", "name"])),
            ("rollback", base.rollback),
            ("sample", base.usingSample(sample)),
            ("table sample", base.tableSample(tableSample)),
            ("schema keyword", base.schema),
            ("schema name", base.schema("analytics")),
            ("select keyword", base.select),
            ("select fields", base.select([value])),
            ("semicolon", base.semicolon),
            ("set keyword", base.set),
            ("set predicate", base.set(predicate)),
            ("space", base.space),
            ("table keyword", base.table),
            ("table name", base.table("events")),
            ("timestamp keyword", base.timestamp),
            ("timestamp fields", base.timestamp([value])),
            ("to", base.to),
            ("type keyword", base.type),
            ("type schema name", base.type("analytics", "label")),
            ("unique", base.unique),
            ("update keyword", base.update),
            ("update tables", base.update([table])),
            ("value subscript", base[any: value]),
            ("value keyword", base.value),
            ("value argument", base.value(value)),
            ("values keyword", base.values),
            ("values items", base.values([value])),
            ("values array", base.values(array: [[value], [Path.Column("other")]])),
            ("where keyword", base.where),
            ("where predicate", base.where(predicate)),
            ("where exists", base.whereExists(table)),
            ("where not exists", base.whereNotExists(table)),
            ("join condition", base.join(.inner, table, on: predicate)),
            ("join match and on", base.join(.inner, table, matchCondition: predicate, on: predicate)),
            ("window", base.window(value)),
            ("alias keyword", base.as),
            ("all keyword helper", base.all),
            ("using sample", base.usingSample(sample))
        ]
        verify(cases)
    }

    @Test("Expression and whole-value fluent declarations")
    func wholeValueTransforms() {
        let value = Path.Column("value")
        let predicate: any SwifQLable = Path.Column("ready") == true
        let cases: [(String, any SwifQLable)] = [
            ("and expression", base.and(predicate)),
            ("any keyword", base.any),
            ("any subquery", base.any(Select { value })),
            ("cast", base.as(.text)),
            ("asterisk", base.asterisk),
            ("exclude star", base.exclude("blocked")),
            ("replace star", base.replace(StarReplacement(value, as: "replacement"))),
            ("rename star", base.rename(StarRename("old", to: "new"))),
            ("between", base.between(value)),
            ("exists keyword", base.exists),
            ("exists predicate", base.exists(Select { value })),
            ("ilike", base.iLike("pattern")),
            ("in", base.in([Path.Column("one"), Path.Column("two")])),
            ("is not null", base.isNotNull),
            ("is null", base.isNull),
            ("not keyword", base.not),
            ("not expression", base.not(predicate)),
            ("not between", base.notBetween(value)),
            ("not exists", base.notExists(Select { value })),
            ("not ilike", base.notILike("pattern")),
            ("not in", base.notIn([Path.Column("one"), Path.Column("two")])),
            ("over keyword", base.over),
            ("over query", base.over(Select { value })),
            ("overlaps keyword", base.overlaps),
            ("overlaps fields", base.overlaps([value])),
            ("subscript", base[value]),
            ("glob", base.glob("pattern")),
            ("similar to", base.similarTo("pattern")),
            ("not similar to", base.notSimilarTo("pattern")),
            ("not like", base.notLike("pattern"))
        ]
        verify(cases)
    }

    @Test("Global postfix, infix, and prefix operators retain the complete current value")
    func globalOperators() {
        let value = Path.Column("rhs")
        let cases: [(String, any SwifQLable)] = [
            ("cast operator", base => Type.text),
            ("plus", base + value),
            ("plus alias", base ++ value),
            ("minus", base - value),
            ("minus alias", base -- value),
            ("multiply", base * value),
            ("multiply alias", base ** value),
            ("divide", base / value),
            ("percent prefix", %(base)),
            ("percent postfix", (base)%),
            ("open one", |(base)),
            ("open two", ||(base)),
            ("open three", |||(base)),
            ("open four", ||||(base)),
            ("open five", |||||(base)),
            ("open six", ||||||(base)),
            ("close one", (base)|),
            ("close two", (base)||),
            ("close three", (base)|||),
            ("close four", (base)||||),
            ("close five", (base)|||||),
            ("close six", (base)||||||),
            ("star postfix", (base)*),
            ("qualified star postfix", (base).*)
        ]
        for (name, result) in cases {
            #expect(result.prepare(.psql).plain.contains("probe_suffix"), "\(name) dropped the suffix")
        }

        let predicates: [(String, any SwifQLable)] = [
            ("greater", base > value),
            ("less", base < value),
            ("greater equal", base >= value),
            ("less equal", base <= value),
            ("equal", base == value),
            ("not equal", base != value),
            ("and", base && value),
            ("or", base || value),
            ("contains", base ||> value),
            ("contained by", base <|| value),
            ("between operator", base <> value),
            ("literal tilde value", base ~ SwifQLableParts(parts: [SwifQLPartOperator.custom("TAIL")])),
            ("literal tilde operator", base ~ SwifQLPartOperator.custom("TAIL"))
        ]
        for (name, result) in predicates {
            #expect(result.prepare(.psql).plain.contains("probe_suffix"), "\(name) dropped the suffix")
        }
    }

    @Test("Constrained generic comparison operators preserve a suffix-bearing SwifQLable operand")
    func genericKeyPathPredicates() {
        let path = Design037RootSuffixUniversalPath()
        let cases: [(String, any SwifQLable)] = [
            ("enum equality", path == .active),
            ("raw-value equality", path == "active"),
            ("enum inequality", path != .active),
            ("raw-value inequality", path != "active")
        ]

        for (name, value) in cases {
            let op = name.contains("inequality") ? "!=" : "="
            let expected = "SELECT \"root_column\" as \"probe_suffix\" \(op) 'active'"
            #expect(value.prepare(.psql).plain == expected, "\(name) changed operand order or folded the suffix")
        }
    }

    @Test("Binds keep source order across continuation and whole-value paths")
    func bindOrder() {
        let boundBase: any SwifQLable = Select { Path.Column("id") }
            .as(Path.Column("suffix_tag") == "suffix-bind")
        let inserted = boundBase.insertInto(Path.Table("target"))
            .values([Path.Column("payload") == "insert-bind"])
        let insert = inserted.prepare(.psql).splitted
        #expect(insert.values.map { String(describing: $0) } == ["suffix-bind", "insert-bind"])

        let updated = boundBase.update([Path.Table("target")])
            .set(Path.Column("id") == "set-bind")
            .where(Path.Column("id") == "where-bind")
        let update = updated.prepare(.psql).splitted
        #expect(update.values.map { String(describing: $0) } == ["suffix-bind", "set-bind", "where-bind"])

        let deleted = boundBase.delete(from: Path.Table("target"))
            .where(Path.Column("id") == "delete-bind")
        let delete = deleted.prepare(.psql).splitted
        #expect(delete.values.map { String(describing: $0) } == ["suffix-bind", "delete-bind"])

        let merged = boundBase.merge(into: Path.Table("target"))
            .using(Path.Table("source"))
            .on(Path.Column("id") == "merge-on-bind")
            .when.matched.then.update.set(Path.Column("id") == "merge-set-bind")
        let merge = merged.prepare(.duck).splitted
        #expect(merge.values.map { String(describing: $0) } == ["suffix-bind", "merge-on-bind", "merge-set-bind"])

        let attached = boundBase.attach(
            "memory",
            options: [.compress(Path.Column("codec") == "attach-bind")]
        )
        let attach = attached.prepare(.duck).splitted
        #expect(attach.values.map { String(describing: $0) } == ["suffix-bind", "attach-bind"])

        let transformed = (boundBase + (Path.Column("rhs") == "expression-bind")).prepare(.psql).splitted
        #expect(transformed.values.map { String(describing: $0) } == ["suffix-bind", "expression-bind"])
    }

    @Test("DML continuation retains sibling suffix during embedding")
    func dml() {
        let insert = root.insert.into[table: Path.Table("Target")].newColumns(NewColumn("id", .int)).values(7)
        let actual = From { insert }.prepare(.psql).plain
        #expect(actual == #"FROM (SELECT "id") as "suffix" INSERT INTO "Target" ("id" int) (7)"#, "actual=\(actual)")
    }

    @Test("DML SET and WHERE continuations retain sibling suffix")
    func updateSetWhere() {
        let query = root.update(Path.Table("Target")).set(Path.Column("id") == 7).where(Path.Column("id") == 9)
        let actual = From { query }.prepare(.psql).plain
        #expect(actual == #"FROM (SELECT "id") as "suffix" UPDATE "Target" SET "id" = 7 WHERE "id" = 9"#, "actual=\(actual)")
    }

    @Test("DML delete and truncate continuations retain sibling suffix")
    func deleteTruncate() {
        let deleted = root.delete(from: Path.Table("Target"))
        let truncated = root.truncate(Path.Table("Target"))
        #expect(From { deleted }.prepare(.psql).plain == #"FROM (SELECT "id") as "suffix" DELETE FROM "Target""#)
        #expect(From { truncated }.prepare(.psql).plain == #"FROM (SELECT "id") as "suffix" TRUNCATE "Target""#)
    }

    @Test("MERGE continuation retains sibling suffix")
    func merge() {
        let query = root.merge(into: Path.Table("Target")).using(Path.Table("Source")).on(Path.Column("id") == Path.Column("otherId")).when.matched.then.update.set(Path.Column("id") == 8).mergeAction
        let actual = From { query }.prepare(.psql).plain
        #expect(actual == #"FROM (SELECT "id") as "suffix" MERGE INTO "Target" USING "Source" ON "id" = "otherId" WHEN MATCHED THEN UPDATE SET "id" = 8 merge_action"#, "actual=\(actual)")
    }

    @Test("DDL statement helpers retain sibling suffix")
    func ddl() {
        let attached = root.attach("memory", options: [])
        let indexed = root.indexItems(IndexItem.expression(Path.Column("id")))
        let created = root.type(.text)
        #expect(From { attached }.prepare(.psql).plain.hasPrefix(#"FROM (SELECT "id") as "suffix" ATTACH"#))
        #expect(From { indexed }.prepare(.psql).plain == #"FROM (SELECT "id") as "suffix" (("id"))"#)
        #expect(From { created }.prepare(.psql).plain == #"FROM (SELECT "id") as "suffix" TYPE text"#)
    }

    @Test("Expression operations retain sibling suffix and operand order")
    func expressions() {
        let arithmetic = root + Path.Column("other")
        let predicate = root == "bound"
        let inExpr = root.in(Path.Column("one"), Path.Column("two"))
        let nullExpr = root.isNull
        let notBetween = root.notBetween(Path.Column("range"))
        let likeExpr = root.like("pattern")
        let actual = [arithmetic, predicate, inExpr, nullExpr, notBetween, likeExpr].map { value in From { value }.prepare(.psql).plain }
        let expected = [
            #"FROM (SELECT "id") as "suffix" + "other""#,
            #"FROM (SELECT "id") as "suffix" = 'bound'"#,
            #"FROM (SELECT "id") as "suffix" IN ("one", "two")"#,
            #"FROM (SELECT "id") as "suffix" IS NULL"#,
            #"FROM (SELECT "id") as "suffix" NOT BETWEEN "range""#,
            #"FROM (SELECT "id") as "suffix" LIKE 'pattern'"#,
        ]
        #expect(actual == expected, "actual=\(actual)")
    }

    @Test("Public raw and keyword helpers retain sibling suffix")
    func rawAndKeywords() {
        let actual = From { root.raw("TAIL").raw("END") }.prepare(.psql).plain
        #expect(actual == #"FROM (SELECT "id") as "suffix" TAIL END"#, "actual=\(actual)")
    }
    @Test("Forwarding overloads and labeled subscripts preserve root suffixes")
    func forwardingOverloads() {
        let table = Path.Table("target")
        let value = Path.Column("value")
        let other = Path.Column("other")
        let predicate: any SwifQLable = Path.Column("ready") == true
        let newColumn = NewColumn("id", .int)
        let withItem = With(Path.Table("cte"), Select { value })
        let cases: [(String, any SwifQLable)] = [
            ("attach option variadic", base.attach("memory", options: .compress("zstd"))),
            ("copy to option variadic", base.copy(table, to: Path.Table("file"), options: .format("csv"))),
            ("copy from option variadic", base.copy(table, from: other, options: .format("csv"))),
            ("copy query option variadic", base.copy(query: Select { value }, to: Path.Table("file"), options: .format("csv"))),
            ("copy database option variadic", base.copy(fromDatabase: Path.Catalog("source"), to: Path.Catalog("destination"), options: .format("csv"))),
            ("table definitions variadic", base.tableDefinitions(value, other)),
            ("index items variadic", base.indexItems(.column("id"), .column("name"))),
            ("macro parameters variadic", base.macroParameters(MacroParameter("p", .int), MacroParameter("q", .text))),
            ("complete MERGE convenience", base.merge(into: table, using: Path.Table("source"), on: predicate)),
            ("conflict paths variadic", base.conflict("id", "name")),
            ("filter predicates variadic", base.filter(where: predicate, value == "x")),
            ("from tables variadic", base.from(table, Path.Table("source"))),
            ("group by array", base.groupBy([value, other])),
            ("group by variadic", base.groupBy(value, other)),
            ("IN variadic", base.in(Path.Column("one"), Path.Column("two"))),
            ("new columns variadic", base.newColumns(newColumn, NewColumn("name", .text))),
            ("new columns subscript variadic", base[newColumns: newColumn, NewColumn("name", .text)]),
            ("new columns subscript array", base[newColumns: [newColumn]]),
            ("fields variadic", base.fields(value, other)),
            ("fields subscript variadic", base[fields: value, other]),
            ("fields subscript array", base[fields: [value, other]]),
            ("items variadic", base.items(value, other)),
            ("items subscript variadic", base[items: value, other]),
            ("items subscript array", base[items: [value, other]]),
            ("insertInto fields variadic", base.insertInto(table, fields: value, other)),
            ("insertInto fields array", base.insertInto(table, fields: [value, other])),
            ("insertInto target", base.insertInto(table)),
            ("orderBy hybrid operator", base.orderBy(.random)),
            ("orderBy expression", base.orderBy(value)),
            ("orderBy items array", base.orderBy([.asc(value), .desc(other)])),
            ("orderBy items variadic", base.orderBy(.asc(value), .desc(other))),
            ("over partition and order variadic", base.over(partitionBy: value, orderBy: .asc(other))),
            ("over partition and order array", base.over(partitionBy: value, orderBy: [.asc(other)])),
            ("overlaps variadic", base.overlaps(value, other)),
            ("returning paths variadic", base.returning("id", "name")),
            ("select fields variadic", base.select(value, other)),
            ("timestamp fields variadic", base.timestamp(value, other)),
            ("type string overload", base.type("label")),
            ("update tables variadic", base.update(table, Path.Table("source"))),
            ("values subscript variadic", base[values: value, other]),
            ("values subscript array", base[values: [value, other]]),
            ("values variadic", base.values(value, other)),
            ("values array variadic", base.values(array: [value], [other])),
            ("with array", base.with([withItem])),
            ("window as query", base.window(value, as: Select { other })),
            ("window partition variadic", base.window(value, asPartitionBy: other, orderBy: .asc(value))),
            ("window partition array", base.window(value, asPartitionBy: other, orderBy: [.asc(value)])),
            ("enum variadic", base.enum("one", "two")),
            ("UNPIVOT INTO single", base.unpivot(table).into(name: "kind", value: "value")),
            ("UNPIVOT INTO variadic", base.unpivot(table).into(name: "kind", values: "first", "second"))
        ]
        verify(cases)

        let union = base.union(allByName: Select { value }).prepare(.psql).plain
        #expect(union == #"(SELECT "root_column") as "probe_suffix" UNION ALL BY NAME (SELECT "value")"#)
    }

    @Test("Remaining JOIN, predicate, and set-result overloads preserve ordered input")
    func joinPredicateAndSetOverloads() {
        let table = Path.Table("joined")
        let value = Path.Column("value")
        let other = Path.Column("other")
        let predicate: any SwifQLable = Path.Column("ready") == true
        let joins: [(String, any SwifQLable)] = [
            ("JOIN match condition USING variadic", base.join(table, matchCondition: predicate, using: "id", "name")),
            ("JOIN mode match condition USING variadic", base.join(.inner, table, matchCondition: predicate, using: "id", "name")),
            ("JOIN match condition USING array", base.join(table, matchCondition: predicate, using: ["id", "name"])),
            ("JOIN mode match condition USING array", base.join(.inner, table, matchCondition: predicate, using: ["id", "name"])),
            ("JOIN USING variadic", base.join(table, using: "id", "name")),
            ("JOIN mode USING variadic", base.join(.inner, table, using: "id", "name")),
            ("JOIN USING array", base.join(table, using: ["id", "name"])),
            ("JOIN mode USING array", base.join(.inner, table, using: ["id", "name"]))
        ]
        verify(joins)
        verify([("OR expression", base.or(predicate)), ("NOT IN variadic", base.notIn(value, other))])

        let lhs = Select { Path.Column("root_column") }.as("probe_suffix")
        let rhs = Select { Path.Column("other") }
        let intersectAll = lhs.intersect(all: rhs).prepare(.psql).plain
        let exceptAll = lhs.except(all: rhs).prepare(.psql).plain
        #expect(intersectAll.contains(#"as "probe_suffix" INTERSECT ALL"#))
        #expect(exceptAll.contains(#"as "probe_suffix" EXCEPT ALL"#))
    }


    @Test("Array and infix function reconstruction preserve root and suffix as siblings")
    func aggregateAndInfixConstructors() {
        let arrayItems = [
            Design037RootSuffixArrayElement(parts: base.parts),
            Design037RootSuffixArrayElement(parts: Path.Column("later").parts)
        ]
        let array = arrayItems.separator(.comma)
        let concatenated = Fn.concatStrings(lhs: base, rhs: Path.Column("later"))

        for (name, value, continuationToken) in [
            ("array separator", array, ","),
            ("string concatenation", concatenated, "||")
        ] {
            guard let frame = value.parts.first as? SwifQLStructuralFramePart else {
                Issue.record("\(name): structural root was lost")
                continue
            }
            #expect(SwifQLableParts(parts: frame.children).prepare(.psql).plain == #"SELECT "root_column""#)
            let suffix = SwifQLableParts(parts: Array(value.parts.dropFirst())).prepare(.psql).plain
            #expect(suffix.contains(#"as "probe_suffix"#), "\(name): alias suffix disappeared")
            #expect(suffix.contains(continuationToken), "\(name): continuation disappeared")
            #expect(suffix.hasSuffix(#""later""#), "\(name): later operand moved: \(suffix)")
        }
    }

}
