import Foundation
import Testing
@testable import SwifQL

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

@Suite("Declarative query core")
struct DeclarativeQueryCoreTests: SwifQLTests {
    // MARK: - T01 existing root compatibility

    @Test("T01 bare SwifQL still renders as an empty statement root")
    func t01BareRoot() {
        check(
            SwifQL,
            .psql(""),
            .mysql(""),
            .duck("")
        )
        #expect(SwifQL.parts.count == 1)
        #expect(SwifQL.parts.first is SwifQLStructuralFramePart)
    }

    @Test("T01 unary SwifQL(query) still wraps existing queries")
    func t01UnaryRoot() {
        let existing = SwifQL.select(1)
        let wrapped = SwifQL(existing)
        #expect(wrapped.prepare(.psql).plain == existing.prepare(.psql).plain)
        #expect(wrapped.prepare(.psql).splitted.query == existing.prepare(.psql).splitted.query)
        #expect(wrapped.prepare(.psql).splitted.values.map { "\($0)" } == existing.prepare(.psql).splitted.values.map { "\($0)" })
    }

    // MARK: - T02 empty root builder

    @Test("T02 empty SwifQL {} matches bare SwifQL")
    func t02EmptyBuilder() {
        let built = SwifQL {}
        check(built, all: SwifQL.prepare(.psql).plain)
        #expect(built.prepare(.psql).plain == SwifQL.prepare(.psql).plain)
        #expect(built.prepare(.psql).splitted.query == SwifQL.prepare(.psql).splitted.query)
        #expect(built.parts.count == SwifQL.parts.count)
        #expect(built.parts.first is SwifQLStructuralFramePart)
    }

    // MARK: - T03 single existing framed query

    @Test("T03 single framed SELECT/FROM preserves SQL, binds, and root frame")
    func t03SingleFramedQuery() {
        let table = Path.Table("CarBrands")
        let q = SwifQL.select(table.column("name"), "seed").from(table)

        let wrapped = SwifQL {
            q
        }

        check(
            wrapped,
            .psql(#"SELECT "CarBrands"."name", 'seed' FROM "CarBrands""#, #"SELECT "CarBrands"."name", $1 FROM "CarBrands""#),
            .mysql("SELECT CarBrands.name, 'seed' FROM CarBrands", "SELECT CarBrands.name, ? FROM CarBrands"),
            .duck(#"SELECT "CarBrands"."name", 'seed' FROM "CarBrands""#, #"SELECT "CarBrands"."name", $1 FROM "CarBrands""#)
        )

        #expect(wrapped.prepare(.psql).plain == q.prepare(.psql).plain)
        #expect(wrapped.prepare(.psql).splitted.query == q.prepare(.psql).splitted.query)
        #expect(
            wrapped.prepare(.psql).splitted.values.map { "\($0)" }
                == q.prepare(.psql).splitted.values.map { "\($0)" }
        )
        #expect(wrapped.prepare(.mysql).plain == q.prepare(.mysql).plain)
        #expect(wrapped.prepare(.duck).plain == q.prepare(.duck).plain)

        #expect(wrapped.parts.count == 1)
        let root = wrapped.parts.first as? SwifQLStructuralFramePart
        #expect(root?.region == .statement)
    }

    // MARK: - T04 multiple neutral fragments

    @Test("T04 multiple neutral fragments preserve source order and spacing")
    func t04MultipleNeutralFragments() {
        let a = SwifQLableParts(parts: SwifQLPartOperator.custom("ALPHA"))
        let b = SwifQLableParts(parts: SwifQLPartOperator.custom("BETA"))
        let c = SwifQLableParts(parts: SwifQLPartOperator.custom("GAMMA"))

        let built = SwifQL {
            a
            b
            c
        }

        #expect(built.prepare(.psql).plain == "ALPHA BETA GAMMA")

        let withGroups = SwifQL {
            a
            if true {
                b
            }
            c
        }
        #expect(withGroups.prepare(.psql).plain == "ALPHA BETA GAMMA")

        let missingMiddle = SwifQL {
            a
            if false {
                b
            }
            c
        }
        #expect(missingMiddle.prepare(.psql).plain == "ALPHA GAMMA")
    }

    // MARK: - T05 if true / false

    @Test("T05 optional branch appears and disappears")
    func t05IfTrueFalse() {
        let yes = SwifQLableParts(parts: SwifQLPartOperator.custom("YES_PART"))
        let no = SwifQLableParts(parts: SwifQLPartOperator.custom("NO_PART"))

        let onTrue = SwifQL {
            if true {
                yes
            }
        }
        #expect(onTrue.prepare(.psql).plain == "YES_PART")

        let onFalse = SwifQL {
            if false {
                no
            }
        }
        #expect(onFalse.prepare(.psql).plain == SwifQL.prepare(.psql).plain)
    }

    // MARK: - T06 if/else

    @Test("T06 if/else contributes exactly one finalized branch")
    func t06IfElse() {
        let thenPart = SwifQLableParts(parts: SwifQLPartOperator.custom("THEN_PART"))
        let elsePart = SwifQLableParts(parts: SwifQLPartOperator.custom("ELSE_PART"))

        let onTrue = SwifQL {
            if true {
                thenPart
            } else {
                elsePart
            }
        }
        #expect(onTrue.prepare(.psql).plain == "THEN_PART")

        let onFalse = SwifQL {
            if false {
                thenPart
            } else {
                elsePart
            }
        }
        #expect(onFalse.prepare(.psql).plain == "ELSE_PART")
    }

    // MARK: - T07 optional binding

    @Test("T07 optional binding present vs nil")
    func t07OptionalBinding() {
        let present: String? = "BOUND"
        let absent: String? = nil

        let withValue = SwifQL {
            if let present {
                SwifQLableParts(parts: SwifQLPartOperator.custom(present))
            }
        }
        #expect(withValue.prepare(.psql).plain == "BOUND")

        let withoutValue = SwifQL {
            if let value = absent {
                SwifQLableParts(parts: SwifQLPartOperator.custom(value))
            }
        }
        #expect(withoutValue.prepare(.psql).plain == SwifQL.prepare(.psql).plain)
    }

    // MARK: - T08 for loop

    @Test("T08 for-loop iterations finalize independently in source order")
    func t08ForLoop() {
        let built = SwifQL {
            for name in ["ONE", "TWO", "THREE"] {
                SwifQLableParts(parts: SwifQLPartOperator.custom(name))
            }
        }
        #expect(built.prepare(.psql).plain == "ONE TWO THREE")

        let empty = SwifQL {
            for name in [String]() {
                SwifQLableParts(parts: SwifQLPartOperator.custom(name))
            }
        }
        #expect(empty.prepare(.psql).plain == SwifQL.prepare(.psql).plain)
    }

    // MARK: - T09 finalized group then new fragment

    @Test("T09 independent fragment starts after a finalized group")
    func t09FinalizedGroupThenFragment() {
        let inside = SwifQLableParts(parts: SwifQLPartOperator.custom("INSIDE"))
        let after = SwifQLableParts(parts: SwifQLPartOperator.custom("AFTER"))

        let built = SwifQL {
            if true {
                inside
            }
            after
        }
        #expect(built.prepare(.psql).plain == "INSIDE AFTER")

        let eitherThenAfter = SwifQL {
            if true {
                inside
            } else {
                SwifQLableParts(parts: SwifQLPartOperator.custom("ELSE_IN"))
            }
            after
        }
        #expect(eitherThenAfter.prepare(.psql).plain == "INSIDE AFTER")

        let loopThenAfter = SwifQL {
            for name in ["L1", "L2"] {
                SwifQLableParts(parts: SwifQLPartOperator.custom(name))
            }
            after
        }
        #expect(loopThenAfter.prepare(.psql).plain == "L1 L2 AFTER")
    }

    // MARK: - T10 stateful child single evaluation

    @Test("T10 stateful child parts getter evaluates exactly once")
    func t10StatefulChildSingleEvaluation() {
        let child = CountingPartsChild(payload: [SwifQLPartOperator.custom("STATEFUL")])
        let built = SwifQL {
            child
        }

        #expect(child.partsEvaluationCount == 1)

        let prepared = built.prepare(.psql)
        let observed = built.prepareObservingUnsafeValues(.psql)
        _ = prepared.plain
        _ = prepared.splitted
        _ = observed.prepared.plain
        _ = observed.prepared.splitted

        #expect(child.partsEvaluationCount == 1)
        #expect(built.prepare(.psql).plain == "STATEFUL")
        #expect(child.partsEvaluationCount == 1)
    }

    // MARK: - T11 unsafe-value / preparation observation

    @Test("T11 unsafe values bind once in source order and stay observation-equivalent")
    func t11UnsafeValuePreparationObservation() {
        let first = SwifQLableParts(parts: SwifQLPartUnsafeValue("bind-a"))
        let second = SwifQLableParts(parts: SwifQLPartOperator.custom("MID"))
        let third = SwifQLableParts(parts: SwifQLPartUnsafeValue("bind-b"))

        let built = SwifQL {
            first
            second
            if true {
                third
            }
            if false {
                SwifQLableParts(parts: SwifQLPartUnsafeValue("bind-skip"))
            }
            SwifQLableParts(parts: SwifQLPartUnsafeValue("bind-c"))
        }

        let prepared = built.prepare(.psql)
        let observed = built.prepareObservingUnsafeValues(.psql)

        #expect(prepared.splitted.query == observed.prepared.splitted.query)
        #expect(prepared.plain == observed.prepared.plain)
        #expect(prepared.splitted.values.map { "\($0)" } == observed.prepared.splitted.values.map { "\($0)" })
        #expect(prepared.splitted.values.map { "\($0)" } == ["bind-a", "bind-b", "bind-c"])

        guard case .complete(let occurrences) = observed.unsafeValueTrace else {
            Issue.record("Expected a complete unsafe-value trace")
            return
        }
        #expect(occurrences.count == 3)
    }

    // MARK: - T12 no builder carrier survives into parts

    @Test("T12 final root parts are ordinary structural/ordinary parts only")
    func t12NoBuilderCarrierSurvives() {
        let frag = SwifQLableParts(parts: SwifQLPartOperator.custom("KEEP"))
        let built = SwifQL {
            frag
            if true {
                SwifQLableParts(parts: SwifQLPartOperator.custom("BRANCH"))
            }
            SwifQLableParts(parts: SwifQLPartOperator.custom("TAIL"))
        }

        func assertOrdinary(_ parts: [SwifQLPart]) {
            for part in parts {
                let typeName = String(reflecting: type(of: part))
                #expect(!typeName.contains("SQLBuilder.NeutralItem"))
                #expect(!typeName.contains("SQLBuilder.FinalizedGroup"))
                #expect(!typeName.contains("SQLBuilder.ClosedRoot"))
                #expect(!typeName.contains("SQLBuilder.Root"))
                #expect(!typeName.contains("SQLBuilder.Partial"))
                if let frame = part as? SwifQLStructuralFramePart {
                    assertOrdinary(frame.children)
                }
            }
        }

        assertOrdinary(built.parts)
        #expect(built.prepare(.psql).plain == "KEEP BRANCH TAIL")
    }

    // MARK: - T13 single framed child owner preservation

    @Test("T13 single framed child keeps root owner/frame metadata")
    func t13SingleFramedChildOwnerPreservation() {
        let owner = SwifQLClauseOwner(namespace: "example", name: "dq01")
        let framed = SwifQLableParts(parts: SwifQLStructuralFramePart(
            region: .statement,
            owners: [.groupBy: owner, .orderBy: owner],
            children: [SwifQLPartOperator.custom("OWNED")]
        ))

        let wrapped = SwifQL {
            framed
        }

        #expect(wrapped.parts.count == 1)
        let root = wrapped.parts.first as? SwifQLStructuralFramePart
        #expect(root?.region == .statement)
        #expect(root?.owner(for: .groupBy) == owner)
        #expect(root?.owner(for: .orderBy) == owner)
        #expect(wrapped.structuralOwner(for: .groupBy) == owner)
        #expect(wrapped.prepare(.psql).plain == framed.prepare(.psql).plain)
    }

    // MARK: - T14 current QueryBuilder compatibility

    @Test("T14 existing QueryBuilder remains unchanged")
    func t14QueryBuilderCompatibility() {
        let child = SwifQLableParts(parts: SwifQLPartOperator.custom("QB_CHILD"))
        let builtViaQueryBuilder = withQueryBuilder {
            child
        }
        #expect(builtViaQueryBuilder.prepare(.psql).plain == "QB_CHILD")

        let emptyViaQueryBuilder = withQueryBuilder {}
        #expect(emptyViaQueryBuilder.prepare(.psql).plain == "")

        let conditional = withQueryBuilder {
            if true {
                child
            }
        }
        #expect(conditional.prepare(.psql).plain == "QB_CHILD")

        // DQ-01 root and QueryBuilder remain independent.
        let rootWrapped = SwifQL {
            builtViaQueryBuilder
        }
        #expect(rootWrapped.prepare(.psql).plain == "QB_CHILD")
    }

    // MARK: - Typed-current substrate proof (section 15)

    @Test("Typed-current probe: open state stays concrete and continuation changes it")
    func typedCurrentPositiveProof() {
        let open: SQLBuilder.Partial<OpenProbe> = SQLBuilder.buildPartialBlock(first: OpenProbe(token: "open"))
        #expect(open.current.token == "open")

        let changed: SQLBuilder.Partial<ChangedProbe> = SQLBuilder.buildPartialBlock(
            accumulated: open,
            next: ProbeContinue(token: "next")
        )
        #expect(changed.current.token == "changed:next")

        let finalized = SQLBuilder.buildOptional(Optional(changed))
        // completed holds the finalized OpenProbe; current ChangedProbe finalizes on the boundary.
        #expect(finalized?.fragments.count == 2)

        let afterGroup: SQLBuilder.Partial<SQLBuilder.NeutralItem> = SQLBuilder.buildPartialBlock(
            accumulated: SQLBuilder.buildPartialBlock(first: finalized),
            next: SQLBuilder.NeutralItem(snapshotting: [
                SwifQLPartOperator.custom("AFTER_GROUP")
            ])
        )
        #expect(afterGroup.completed.count == 2)
        #expect(afterGroup.current.finalize().prepare(.psql).plain == "AFTER_GROUP")

        let root = SQLBuilder.buildFinalResult(afterGroup)
        let lowered = root
        #expect(lowered.prepare(.psql).plain.contains("AFTER_GROUP"))
    }
}

// MARK: - QueryBuilder fixture (T14)

private func withQueryBuilder(@QueryBuilder _ body: () -> SwifQLable) -> SwifQLable {
    body()
}

// MARK: - Test-only typed-current probe types (section 15)

private struct OpenProbe: SQLBuilder.FinalizableItem {
    let token: String

    func finalize() -> SwifQLable {
        SwifQLableParts(parts: SwifQLPartOperator.custom("OPEN:\(token)"))
    }
}

private struct ChangedProbe: SQLBuilder.FinalizableItem {
    let token: String

    func finalize() -> SwifQLable {
        SwifQLableParts(parts: SwifQLPartOperator.custom("CHANGED:\(token)"))
    }
}

private struct ProbeContinue {
    let token: String
}

extension SQLBuilder {
    fileprivate static func buildPartialBlock(first: OpenProbe) -> Partial<OpenProbe> {
        Partial(completed: [], current: first)
    }

    fileprivate static func buildPartialBlock(
        accumulated: Partial<OpenProbe>,
        next: ProbeContinue
    ) -> Partial<ChangedProbe> {
        Partial(
            completed: accumulated.completed + [accumulated.current.finalize()],
            current: ChangedProbe(token: "changed:\(next.token)")
        )
    }
}
