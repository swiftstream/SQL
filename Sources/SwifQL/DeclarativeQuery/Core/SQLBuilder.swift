import Foundation

/// Authoring-time result builder for the declarative query surface.
///
/// `SQLBuilder` is a support type only. It is not a public `SQL` root and does
/// not authorize a namespace migration.
@resultBuilder
public enum SQLBuilder {
    /// An open typed item that can finalize into ordinary `SwifQLable` structure.
    public protocol FinalizableItem {
        func finalize() -> SwifQLable
    }

    /// Already-complete neutral fragment captured from an existing `SwifQLable`.
    ///
    /// Child `parts` are snapshotted once at capture time and never retained as a
    /// stateful child for repeated evaluation.
    public struct NeutralItem: FinalizableItem {
        private let snapshot: [SwifQLPart]

        init(snapshotting parts: [SwifQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }
    }

    /// Typed-current partial: completed finalized fragments plus a statically
    /// typed immediately-open `Current`.
    public struct Partial<Current: FinalizableItem> {
        var completed: [SwifQLable]
        var current: Current

        init(completed: [SwifQLable], current: Current) {
            self.completed = completed
            self.current = current
        }
    }

    /// Finalized control-flow boundary. Contains only completed ordinary
    /// fragments and exposes no open continuation target.
    ///
    /// `Source` is a phantom generic used only for builder inference of the
    /// branch's previous open current; the payload is already materialized.
    public struct FinalizedGroup<Source: FinalizableItem> {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    /// Closed/root accumulator after a finalized group. A new independent item
    /// may start later; the previous open current is not exposed.
    public struct ClosedRoot {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    /// Uniform builder output lowered by the current root.
    public struct Root {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    // MARK: - Expression intake

    /// Captures an existing complete `SwifQLable` as a neutral fragment,
    /// evaluating `parts` exactly once.
    public static func buildExpression(_ expression: SwifQLable) -> NeutralItem {
        NeutralItem(snapshotting: expression.parts)
    }

    /// Passes a builder-support item through unchanged (typed-current probes and
    /// future grammar items). Not a universal "any next item after any current"
    /// transition.
    public static func buildExpression<Item: FinalizableItem>(_ item: Item) -> Item {
        item
    }

    // MARK: - Empty / neutral partial composition

    public static func buildBlock() -> ClosedRoot {
        ClosedRoot(fragments: [])
    }

    public static func buildPartialBlock(first: NeutralItem) -> Partial<NeutralItem> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock<C: FinalizableItem>(
        accumulated: Partial<C>,
        next: NeutralItem
    ) -> Partial<NeutralItem> {
        Partial(
            completed: accumulated.completed + [accumulated.current.finalize()],
            current: next
        )
    }

    public static func buildPartialBlock(
        accumulated: ClosedRoot,
        next: NeutralItem
    ) -> Partial<NeutralItem> {
        Partial(completed: accumulated.fragments, current: next)
    }

    // MARK: - Finalized group boundaries

    public static func buildPartialBlock<Source: FinalizableItem>(
        first: FinalizedGroup<Source>
    ) -> ClosedRoot {
        ClosedRoot(fragments: first.fragments)
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        first: FinalizedGroup<Source>?
    ) -> ClosedRoot {
        ClosedRoot(fragments: first?.fragments ?? [])
    }

    public static func buildPartialBlock<C: FinalizableItem, Source: FinalizableItem>(
        accumulated: Partial<C>,
        next: FinalizedGroup<Source>
    ) -> ClosedRoot {
        ClosedRoot(
            fragments: accumulated.completed + [accumulated.current.finalize()] + next.fragments
        )
    }

    public static func buildPartialBlock<C: FinalizableItem, Source: FinalizableItem>(
        accumulated: Partial<C>,
        next: FinalizedGroup<Source>?
    ) -> ClosedRoot {
        ClosedRoot(
            fragments: accumulated.completed + [accumulated.current.finalize()] + (next?.fragments ?? [])
        )
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        accumulated: ClosedRoot,
        next: FinalizedGroup<Source>
    ) -> ClosedRoot {
        ClosedRoot(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        accumulated: ClosedRoot,
        next: FinalizedGroup<Source>?
    ) -> ClosedRoot {
        ClosedRoot(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    // MARK: - Control-flow finalization

    public static func buildOptional<C: FinalizableItem>(
        _ component: Partial<C>?
    ) -> FinalizedGroup<C>? {
        component.map {
            FinalizedGroup<C>(fragments: $0.completed + [$0.current.finalize()])
        }
    }

    public static func buildEither<C: FinalizableItem>(
        first component: Partial<C>
    ) -> FinalizedGroup<C> {
        FinalizedGroup<C>(fragments: component.completed + [component.current.finalize()])
    }

    public static func buildEither<C: FinalizableItem>(
        second component: Partial<C>
    ) -> FinalizedGroup<C> {
        FinalizedGroup<C>(fragments: component.completed + [component.current.finalize()])
    }

    public static func buildArray<C: FinalizableItem>(
        _ components: [Partial<C>]
    ) -> FinalizedGroup<C> {
        FinalizedGroup<C>(
            fragments: components.flatMap { $0.completed + [$0.current.finalize()] }
        )
    }

    // MARK: - Final result

    public static func buildFinalResult(_ component: ClosedRoot) -> Root {
        Root(fragments: component.fragments)
    }

    public static func buildFinalResult<C: FinalizableItem>(
        _ component: Partial<C>
    ) -> Root {
        Root(fragments: component.completed + [component.current.finalize()])
    }

    public static func buildFinalResult<Source: FinalizableItem>(
        _ component: FinalizedGroup<Source>
    ) -> Root {
        Root(fragments: component.fragments)
    }

    public static func buildFinalResult<Source: FinalizableItem>(
        _ component: FinalizedGroup<Source>?
    ) -> Root {
        Root(fragments: component?.fragments ?? [])
    }

    // MARK: - Root lowering

    /// Lowers completed fragments into ordinary existing `SwifQLable` / parts /
    /// structural frames. Builder carriers never survive into final `parts`.
    static func lowerRoot(_ fragments: [SwifQLable]) -> SwifQLable {
        guard !fragments.isEmpty else {
            return SwifQL
        }

        if fragments.count == 1 {
            let only = fragments[0]
            if let frame = only.parts.first as? SwifQLStructuralFramePart {
                switch frame.region {
                case .statement, .setResult:
                    return only
                }
            }
            return SwifQLableParts(rawParts: [
                _SwifQLStructuralComposition.statementFrame(for: only)
            ])
        }

        var result: SwifQLable = SwifQL
        for fragment in fragments {
            result = _SwifQLStructuralComposition.appendStatementContents(
                from: fragment,
                to: result
            )
        }
        return result
    }
}
