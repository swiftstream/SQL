import Foundation

/// Fragment-first composition root.
///
/// Each expression is snapshotted as an ordinary SQL fragment. The builder
/// preserves source order and leaves whole-statement validation to the database.
@resultBuilder
public enum SQLBuilder {
    public protocol FinalizableItem {
        func finalize() -> SwifQLable
    }

    public struct NeutralItem: FinalizableItem {
        private let snapshot: [SwifQLPart]

        init(snapshotting parts: [SwifQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }
    }

    public struct Partial<Current: FinalizableItem> {
        var completed: [SwifQLable]
        var current: Current

        init(completed: [SwifQLable], current: Current) {
            self.completed = completed
            self.current = current
        }
    }

    public struct FinalizedGroup<Source: FinalizableItem> {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    public struct ClosedRoot {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    public struct Root {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    public static func buildExpression(_ expression: any SwifQLable) -> NeutralItem {
        NeutralItem(snapshotting: expression.parts)
    }

    public static func buildBlock() -> ClosedRoot {
        ClosedRoot(fragments: [])
    }

    public static func buildPartialBlock(first item: NeutralItem) -> Partial<NeutralItem> {
        Partial(completed: [], current: item)
    }

    public static func buildPartialBlock<C: FinalizableItem>(
        accumulated: Partial<C>,
        next item: NeutralItem
    ) -> Partial<NeutralItem> {
        Partial(
            completed: accumulated.completed + [accumulated.current.finalize()],
            current: item
        )
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        first group: FinalizedGroup<Source>
    ) -> ClosedRoot {
        ClosedRoot(fragments: group.fragments)
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        first group: FinalizedGroup<Source>?
    ) -> ClosedRoot {
        ClosedRoot(fragments: group?.fragments ?? [])
    }

    public static func buildPartialBlock<C: FinalizableItem, Source: FinalizableItem>(
        accumulated: Partial<C>,
        next group: FinalizedGroup<Source>
    ) -> ClosedRoot {
        ClosedRoot(
            fragments: accumulated.completed
                + [accumulated.current.finalize()]
                + group.fragments
        )
    }

    public static func buildPartialBlock<C: FinalizableItem, Source: FinalizableItem>(
        accumulated: Partial<C>,
        next group: FinalizedGroup<Source>?
    ) -> ClosedRoot {
        ClosedRoot(
            fragments: accumulated.completed
                + [accumulated.current.finalize()]
                + (group?.fragments ?? [])
        )
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        accumulated: ClosedRoot,
        next group: FinalizedGroup<Source>
    ) -> ClosedRoot {
        ClosedRoot(fragments: accumulated.fragments + group.fragments)
    }

    public static func buildPartialBlock<Source: FinalizableItem>(
        accumulated: ClosedRoot,
        next group: FinalizedGroup<Source>?
    ) -> ClosedRoot {
        ClosedRoot(fragments: accumulated.fragments + (group?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: ClosedRoot,
        next item: NeutralItem
    ) -> Partial<NeutralItem> {
        Partial(completed: accumulated.fragments, current: item)
    }

    public static func buildOptional<C: FinalizableItem>(
        _ component: Partial<C>?
    ) -> FinalizedGroup<C>? {
        component.map {
            FinalizedGroup(fragments: $0.completed + [$0.current.finalize()])
        }
    }

    public static func buildEither<C: FinalizableItem>(
        first component: Partial<C>
    ) -> FinalizedGroup<C> {
        FinalizedGroup(fragments: component.completed + [component.current.finalize()])
    }

    public static func buildEither<C: FinalizableItem>(
        second component: Partial<C>
    ) -> FinalizedGroup<C> {
        FinalizedGroup(fragments: component.completed + [component.current.finalize()])
    }

    public static func buildArray<C: FinalizableItem>(
        _ components: [Partial<C>]
    ) -> FinalizedGroup<C> {
        FinalizedGroup(
            fragments: components.flatMap { $0.completed + [$0.current.finalize()] }
        )
    }

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

    static func lowerRoot(_ fragments: [SwifQLable]) -> SwifQLable {
        guard !fragments.isEmpty else { return SwifQL }

        if fragments.count == 1 {
            let only = fragments[0]
            if let frame = only.parts.first as? SwifQLStructuralFramePart,
               frame.region == .statement || frame.region == .setResult {
                return only
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
