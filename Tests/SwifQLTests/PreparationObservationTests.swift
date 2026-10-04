import Foundation
import Testing
@testable import SwifQL

private final class StatefulPartsValue: SwifQLable {
    private let builder: (Int) -> [SwifQLPart]
    private(set) var evaluationCount = 0

    init(builder: @escaping (Int) -> [SwifQLPart]) {
        self.builder = builder
    }

    var parts: [SwifQLPart] {
        evaluationCount += 1
        return builder(evaluationCount)
    }
}

private struct ProbeArrayPart: SwifQLPartArray {
    let elements: [SwifQLable]
}

private final class LegacySamplingObservationDialect: SQLDialect {
    private(set) var samplingCalls = 0

    override func sampling(_ sample: SwifQLPartSampling) -> [SwifQLPart] {
        samplingCalls += 1
        var parts: [SwifQLPart] = [SwifQLPartOperator("LEGACY_SAMPLE(")]
        if let first = sample.arguments.first {
            parts.append(contentsOf: first.value.parts)
        }
        parts.append(SwifQLPartOperator(")"))
        return parts
    }
}

private final class LegacyLambdaObservationDialect: SQLDialect {
    private(set) var lambdaCalls = 0

    override func lambda(_ lambda: SwifQLPartLambda) -> [SwifQLPart] {
        lambdaCalls += 1
        var parts: [SwifQLPart] = [SwifQLPartOperator("LEGACY_LAMBDA(")]
        parts.append(contentsOf: lambda.body)
        parts.append(SwifQLPartOperator(")"))
        return parts
    }
}

private final class LegacyStarReplacementObservationDialect: SQLDialect {
    private(set) var replacementCalls = 0

    override func starReplaceParts(_ part: SwifQLStarReplacePart) -> [SwifQLPart] {
        replacementCalls += 1
        var parts: [SwifQLPart] = [SwifQLPartOperator("LEGACY_REPLACE(")]
        if let first = part.entries.first {
            parts.append(contentsOf: first.expressionParts)
        }
        parts.append(SwifQLPartOperator(")"))
        return parts
    }
}

private final class OptInObservedSamplingDialect: SQLDialect {
    private(set) var observedSamplingCalls = 0

    override func sampling(
        _ sample: SwifQLPartSampling,
        observingUnsafeValues observation: SwifQLUnsafeValueObservation
    ) -> SwifQLObservedParts {
        observedSamplingCalls += 1

        guard sample.arguments.count >= 2 else {
            return .complete(super.sampling(sample))
        }

        let firstParts = sample.arguments[0].value.parts
        let secondParts = sample.arguments[1].value.parts
        guard let firstUnsafe = firstParts.first as? SwifQLPartUnsafeValue else {
            return .complete(super.sampling(sample))
        }

        var parts: [SwifQLPart] = [
            SwifQLPartOperator("OPT("),
            observation.notBound(firstUnsafe),
            SwifQLPartOperator("consumed"),
            SwifQLPartOperator(",")
        ]
        parts.append(contentsOf: secondParts)
        parts.append(SwifQLPartOperator(")"))
        return .complete(parts)
    }
}

private final class CentralObservationDialect: SQLDialect {
    override func bindKey(_ index: Int) -> String { ":\(index)" }

    override func inlineUnsafeValue(
        _ value: Encodable,
        context: SwifQLRenderContext
    ) -> String? {
        guard let value = value as? Int, value == 1 else { return nil }
        return "INLINE_ONE"
    }
}

@Suite("Unsafe-value preparation observation")
struct PreparationObservationTests {
    private func completeOccurrences(
        _ observed: SwifQLObservedPrepared
    ) -> [SwifQLUnsafeValueOccurrence] {
        switch observed.unsafeValueTrace {
        case .complete(let occurrences):
            return occurrences
        case .unavailable:
            Issue.record("Expected a complete unsafe-value trace")
            return []
        }
    }

    private func expectUnavailable(_ observed: SwifQLObservedPrepared) {
        switch observed.unsafeValueTrace {
        case .unavailable:
            break
        case .complete:
            Issue.record("Expected unsafe-value trace to be unavailable")
        }
    }

    private func describedValues(_ prepared: SwifQLPrepared) -> [String] {
        prepared.splitted.values.map { String(describing: $0) }
    }

    private func expectPreparationCompatibility(
        _ query: SwifQLable,
        dialect: SQLDialect
    ) {
        let ordinary = query.prepare(dialect)
        let observed = query.prepareObservingUnsafeValues(dialect).prepared

        #expect(observed.plain == ordinary.plain)
        #expect(observed.splitted.query == ordinary.splitted.query)
        #expect(describedValues(observed) == describedValues(ordinary))
    }

    @Test("O01 ordinary unsafe value records exact bound index")
    func ordinarySingleBoundValue() {
        let query = SwifQLableParts(parts: SwifQLPartUnsafeValue("alpha"))
        let ordinary = query.prepare(.duck)
        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(observed.prepared.plain == ordinary.plain)
        #expect(observed.prepared.splitted.query == ordinary.splitted.query)
        #expect(occurrences.count == 1)
        #expect(occurrences.first?.value as? String == "alpha")
        #expect(occurrences.first?.disposition == .bound(index: 0))
        #expect(observed.prepared.splitted.values.count == 1)
        #expect(observed.prepared.splitted.values[0] as? String == "alpha")
    }

    @Test("O02 repeated unsafe values remain separate ordered occurrences")
    func repeatedBoundValues() {
        let query = SwifQLableParts(parts: [
            SwifQLPartUnsafeValue(7),
            SwifQLPartOperator(","),
            SwifQLPartUnsafeValue(7),
            SwifQLPartOperator(","),
            SwifQLPartUnsafeValue(9)
        ])
        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(occurrences.compactMap { $0.value as? Int } == [7, 7, 9])
        #expect(occurrences.map(\.disposition) == [
            .bound(index: 0),
            .bound(index: 1),
            .bound(index: 2)
        ])
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [7, 7, 9])
    }

    @Test("O03 stateful top-level parts are evaluated once")
    func statefulTopLevelParts() {
        let query = StatefulPartsValue { evaluation in
            [SwifQLPartUnsafeValue(evaluation)]
        }

        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(query.evaluationCount == 1)
        #expect(observed.prepared.plain == "1")
        #expect(observed.prepared.splitted.query == "$1")
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [1])
        #expect(occurrences.compactMap { $0.value as? Int } == [1])
        #expect(occurrences.map(\.disposition) == [.bound(index: 0)])
    }

    @Test("O04 stateful nested array element is evaluated once")
    func statefulNestedArrayElement() {
        let child = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(4)] }
        let arrayPart: SwifQLPart = [child]
        let query = SwifQLableParts(parts: [arrayPart])

        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(child.evaluationCount == 1)
        #expect(observed.prepared.plain == "[4]")
        #expect(observed.prepared.splitted.query == "[$1]")
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [4])
        #expect(occurrences.compactMap { $0.value as? Int } == [4])
        #expect(occurrences.map(\.disposition) == [.bound(index: 0)])
    }

    @Test("O05 structural and scoped recursion preserves depth-first bind order")
    func structuralScopedRecursion() {
        let scope = SwifQLRenderScope(namespace: "tests", name: "nested")
        let frame = SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartUnsafeValue(1),
                SwifQLPartOperator(","),
                SQLScopedPart(
                    scope: scope,
                    parts: [SwifQLPartUnsafeValue(2)]
                ),
                SwifQLPartOperator(","),
                SwifQLPartUnsafeValue(3)
            ]
        )
        let query = SwifQLableParts(parts: frame)

        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(observed.prepared.plain == "1,2,3")
        #expect(observed.prepared.splitted.query == "$1,$2,$3")
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [1, 2, 3])
        #expect(occurrences.compactMap { $0.value as? Int } == [1, 2, 3])
        #expect(occurrences.map(\.disposition) == [
            .bound(index: 0),
            .bound(index: 1),
            .bound(index: 2)
        ])
    }

    @Test("O06 Duck star-pattern unsafe value is not bound while ordinary LIKE remains bound")
    func duckStarPatternNotBound() {
        let pattern = "metric%"
        let star = SwifQL.asterisk.like(pattern)
        let observedStar = star.prepareObservingUnsafeValues(.duck)
        let starOccurrences = completeOccurrences(observedStar)

        #expect(observedStar.prepared.plain == star.prepare(.duck).plain)
        #expect(observedStar.prepared.splitted.query == star.prepare(.duck).splitted.query)
        #expect(observedStar.prepared.splitted.values.isEmpty)
        #expect(starOccurrences.compactMap { $0.value as? String } == [pattern])
        #expect(starOccurrences.map(\.disposition) == [.notBound])

        let ordinary = Path.Column("metric").like(pattern)
        let observedOrdinary = ordinary.prepareObservingUnsafeValues(.duck)
        let ordinaryOccurrences = completeOccurrences(observedOrdinary)
        #expect(observedOrdinary.prepared.splitted.values.count == 1)
        #expect(observedOrdinary.prepared.splitted.values[0] as? String == pattern)
        #expect(ordinaryOccurrences.map(\.disposition) == [.bound(index: 0)])
    }

    @Test("O07 Duck sampling observes one stateful unsafe argument exactly once")
    func duckSamplingStatefulArgument() {
        let child = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(10)] }
        let query = Sample(arguments: [SampleArgument(percentage: child)])

        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(child.evaluationCount == 1)
        #expect(observed.prepared.plain == "USING SAMPLE 10%")
        #expect(observed.prepared.splitted.values.isEmpty)
        #expect(occurrences.compactMap { $0.value as? Int } == [10])
        #expect(occurrences.map(\.disposition) == [.notBound])
    }

    @Test("O08 Duck sampling traces argument, seed, and repeatability in grammar order")
    func duckSamplingRoles() {
        let usingArgument = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(10)] }
        let usingSeed = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(20)] }
        let using = Sample(
            arguments: [SampleArgument(percentage: usingArgument)],
            method: .reservoir,
            seed: usingSeed
        )

        let observedUsing = using.prepareObservingUnsafeValues(.duck)
        let usingOccurrences = completeOccurrences(observedUsing)
        #expect(usingArgument.evaluationCount == 1)
        #expect(usingSeed.evaluationCount == 1)
        #expect(observedUsing.prepared.plain == "USING SAMPLE 10% (reservoir, 20)")
        #expect(observedUsing.prepared.splitted.values.isEmpty)
        #expect(usingOccurrences.compactMap { $0.value as? Int } == [10, 20])
        #expect(usingOccurrences.map(\.disposition) == [.notBound, .notBound])

        let tableArgument = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(30)] }
        let repeatability = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(40)] }
        let table = TableSample(
            arguments: [SampleArgument(rows: tableArgument)],
            method: .system,
            repeatable: repeatability
        )

        let observedTable = table.prepareObservingUnsafeValues(.duck)
        let tableOccurrences = completeOccurrences(observedTable)
        #expect(tableArgument.evaluationCount == 1)
        #expect(repeatability.evaluationCount == 1)
        #expect(observedTable.prepared.plain == "TABLESAMPLE system(30 ROWS) REPEATABLE (40)")
        #expect(observedTable.prepared.splitted.values.isEmpty)
        #expect(tableOccurrences.compactMap { $0.value as? Int } == [30, 40])
        #expect(tableOccurrences.map(\.disposition) == [.notBound, .notBound])
    }

    @Test("O09A rejected Duck sampling traces one direct unsafe without descending into rejected container")
    func duckSamplingRejectedOneUnsafePlusContainer() {
        let nested = StatefulPartsValue { _ in [SwifQLPartUnsafeValue(999)] }
        let rejectedContainer = ProbeArrayPart(elements: [nested])
        let child = StatefulPartsValue { _ in
            [
                SwifQLPartUnsafeValue(51),
                rejectedContainer
            ]
        }
        let query = Sample(arguments: [SampleArgument(percentage: child)])

        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(child.evaluationCount == 1)
        #expect(nested.evaluationCount == 0)
        #expect(
            observed.prepared.plain ==
                "USING SAMPLE <duck_sampling_argument_requires_safe_literal>%"
        )
        #expect(observed.prepared.splitted.values.isEmpty)
        #expect(occurrences.compactMap { $0.value as? Int } == [51])
        #expect(occurrences.map(\.disposition) == [.notBound])
    }

    @Test("O09B rejected Duck sampling traces every direct unsafe in order")
    func duckSamplingRejectedMultipleUnsafeValues() {
        let child = StatefulPartsValue { _ in
            [
                SwifQLPartUnsafeValue(61),
                SwifQLPartOperator("+"),
                SwifQLPartUnsafeValue(62)
            ]
        }
        let query = Sample(arguments: [SampleArgument(percentage: child)])

        let observed = query.prepareObservingUnsafeValues(.duck)
        let occurrences = completeOccurrences(observed)

        #expect(child.evaluationCount == 1)
        #expect(
            observed.prepared.plain ==
                "USING SAMPLE <duck_sampling_argument_requires_safe_literal>%"
        )
        #expect(observed.prepared.splitted.values.isEmpty)
        #expect(occurrences.compactMap { $0.value as? Int } == [61, 62])
        #expect(occurrences.map(\.disposition) == [.notBound, .notBound])
    }

    @Test("O10 built-in lambda observation stays complete and bound across dialects")
    func builtInLambda() {
        let query = SQLLambda("x") { x in x + 7 }

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let ordinary = query.prepare(dialect)
            let observed = query.prepareObservingUnsafeValues(dialect)
            let occurrences = completeOccurrences(observed)

            #expect(observed.prepared.plain == ordinary.plain)
            #expect(observed.prepared.splitted.query == ordinary.splitted.query)
            #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [7])
            #expect(occurrences.compactMap { $0.value as? Int } == [7])
            #expect(occurrences.map(\.disposition) == [.bound(index: 0)])
        }
    }

    @Test("O11 built-in star replacement observation preserves bind order")
    func builtInStarReplacement() {
        let query = SwifQL.asterisk.replace(
            StarReplacement("fallback", as: "value"),
            StarReplacement(8, as: "count")
        )

        for dialect in [SQLDialect.psql, .mysql, .duck] {
            let ordinary = query.prepare(dialect)
            let observed = query.prepareObservingUnsafeValues(dialect)
            let occurrences = completeOccurrences(observed)

            #expect(observed.prepared.plain == ordinary.plain)
            #expect(observed.prepared.splitted.query == ordinary.splitted.query)
            #expect(describedValues(observed.prepared) == describedValues(ordinary))
            #expect(occurrences.compactMap { $0.value as? String } == ["fallback"])
            #expect(occurrences.count == 2)
            #expect(occurrences[1].value as? Int == 8)
            #expect(occurrences.map(\.disposition) == [
                .bound(index: 0),
                .bound(index: 1)
            ])
        }
    }

    @Test("O12 legacy custom sampling override stays exact and fails closed")
    func legacyCustomSampling() {
        let query = Sample(arguments: [SampleArgument(5)])
        let ordinaryDialect = LegacySamplingObservationDialect()
        let observedDialect = LegacySamplingObservationDialect()

        let ordinary = query.prepare(ordinaryDialect)
        let observed = query.prepareObservingUnsafeValues(observedDialect)

        #expect(ordinaryDialect.samplingCalls == 1)
        #expect(observedDialect.samplingCalls == 1)
        #expect(observed.prepared.plain == ordinary.plain)
        #expect(observed.prepared.splitted.query == ordinary.splitted.query)
        #expect(describedValues(observed.prepared) == describedValues(ordinary))
        expectUnavailable(observed)
    }

    @Test("O13 legacy custom lambda override stays exact and fails closed")
    func legacyCustomLambda() {
        let query = SQLLambda("x") { x in x + 9 }
        let ordinaryDialect = LegacyLambdaObservationDialect()
        let observedDialect = LegacyLambdaObservationDialect()

        let ordinary = query.prepare(ordinaryDialect)
        let observed = query.prepareObservingUnsafeValues(observedDialect)

        #expect(ordinaryDialect.lambdaCalls == 1)
        #expect(observedDialect.lambdaCalls == 1)
        #expect(observed.prepared.plain == ordinary.plain)
        #expect(observed.prepared.splitted.query == ordinary.splitted.query)
        #expect(describedValues(observed.prepared) == describedValues(ordinary))
        expectUnavailable(observed)
    }

    @Test("O14 legacy custom star replacement override stays exact and fails closed")
    func legacyCustomStarReplacement() {
        let query = SwifQL.asterisk.replace(StarReplacement(11, as: "value"))
        let ordinaryDialect = LegacyStarReplacementObservationDialect()
        let observedDialect = LegacyStarReplacementObservationDialect()

        let ordinary = query.prepare(ordinaryDialect)
        let observed = query.prepareObservingUnsafeValues(observedDialect)

        #expect(ordinaryDialect.replacementCalls == 1)
        #expect(observedDialect.replacementCalls == 1)
        #expect(observed.prepared.plain == ordinary.plain)
        #expect(observed.prepared.splitted.query == ordinary.splitted.query)
        #expect(describedValues(observed.prepared) == describedValues(ordinary))
        expectUnavailable(observed)
    }

    @Test("O15 opt-in custom observed hook interleaves not-bound and bound occurrences")
    func optInCustomObservedHook() {
        let dialect = OptInObservedSamplingDialect()
        let query = Sample(arguments: [SampleArgument(101), SampleArgument(202)])

        let observed = query.prepareObservingUnsafeValues(dialect)
        let occurrences = completeOccurrences(observed)

        #expect(dialect.observedSamplingCalls == 1)
        #expect(observed.prepared.plain == "OPT(consumed,202)")
        #expect(observed.prepared.splitted.query == "OPT(consumed,?)")
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [202])
        #expect(occurrences.compactMap { $0.value as? Int } == [101, 202])
        #expect(occurrences.map(\.disposition) == [.notBound, .bound(index: 0)])
    }

    @Test("O16 ordinary custom dialect central path observes inline and bound values completely")
    func ordinaryCustomDialectCentralPath() {
        let query = SwifQLableParts(parts: [
            SwifQLPartUnsafeValue(1),
            SwifQLPartOperator(","),
            SwifQLPartUnsafeValue(2)
        ])
        let observed = query.prepareObservingUnsafeValues(CentralObservationDialect())
        let occurrences = completeOccurrences(observed)

        #expect(observed.prepared.plain == "INLINE_ONE,2")
        #expect(observed.prepared.splitted.query == "INLINE_ONE,:1")
        #expect(observed.prepared.splitted.values.compactMap { $0 as? Int } == [2])
        #expect(occurrences.compactMap { $0.value as? Int } == [1, 2])
        #expect(occurrences.map(\.disposition) == [.notBound, .bound(index: 0)])
    }

    @Test("O17 observed preparation preserves representative built-in output and value order")
    func builtInCompatibilityMatrix() {
        let arrayPart = [1, 2]
        let structuralScope = SwifQLRenderScope(namespace: "tests", name: "compatibility")
        let structural = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            children: [
                SwifQLPartUnsafeValue(3),
                SwifQLPartOperator(","),
                SQLScopedPart(
                    scope: structuralScope,
                    parts: [SwifQLPartUnsafeValue(4)]
                )
            ]
        ))

        let queries: [SwifQLable] = [
            SwifQL.select(1, 2),
            SwifQLableParts(parts: [arrayPart]),
            Sample(SampleSize(percentage: 10), method: .reservoir, seed: 42),
            SQLLambda("x") { x in x + 1 },
            SwifQL.asterisk.replace(StarReplacement(1, as: "value")),
            SwifQL.asterisk.like("metric%"),
            structural
        ]

        for query in queries {
            for dialect in [SQLDialect.psql, .mysql, .duck] {
                expectPreparationCompatibility(query, dialect: dialect)
            }
        }
    }
}
