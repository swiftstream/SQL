import Foundation

/// SELECT projection / modifier result builder.
///
/// Typed-current composition (DESIGN-028): an open projection stays statically
/// aliasable until `As`, a new projection, a control-flow boundary, or final
/// lowering. Duplicate-row modifiers own a single first-and-unique header slot
/// (DESIGN-029). Final output lowers to ordinary parts and exactly one
/// statement structural frame — no second AST.
@resultBuilder
public enum SelectBuilder {
    // MARK: - Public support types

    /// Open projection item. Snapshots one expression's `parts` exactly once.
    public struct ProjectionItem: SQLBuilder.AliasableItem {
        public typealias Aliased = AliasedProjectionItem

        private let snapshot: [SwifQLPart]

        init(snapshotting parts: [SwifQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }

        public func addingAlias(_ name: String) -> AliasedProjectionItem {
            var parts = snapshot
            parts.appendSpaceIfNeeded()
            parts.append(o: .as)
            parts.append(o: .space)
            parts.append(SwifQLPartAlias(name))
            return AliasedProjectionItem(snapshotting: parts)
        }
    }

    /// Already-aliased projection. Not aliasable: repeated `As` rejects.
    public struct AliasedProjectionItem: SQLBuilder.FinalizableItem {
        private let snapshot: [SwifQLPart]

        init(snapshotting parts: [SwifQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }
    }

    /// Typed SELECT duplicate-row modifier slot (first and unique).
    public struct Header {
        enum Kind {
            case absent
            case present(prefix: [SwifQLPart], carriesProjection: Bool)
        }

        let kind: Kind

        init(kind: Kind) {
            self.kind = kind
        }

        static var absentSlot: Header {
            Header(kind: .absent)
        }

        /// Snapshot `modifier.parts` exactly once; mode from internal metadata only.
        static func capturing(_ modifier: Distinct) -> Header {
            Header(
                kind: .present(
                    prefix: modifier.parts,
                    carriesProjection: modifier._declarativeCarriesProjection
                )
            )
        }

        static func capturing(_ modifier: DistinctOn) -> Header {
            Header(
                kind: .present(
                    prefix: modifier.parts,
                    carriesProjection: false
                )
            )
        }
    }

    /// Typed-current projection partial. SELECT-header ownership is carried only
    /// by `HeaderPartial` and never enters projection control-flow finalization.
    public struct Partial<Current: SQLBuilder.FinalizableItem> {
        let completed: [SwifQLable]
        let current: Current

        init(completed: [SwifQLable], current: Current) {
            self.completed = completed
            self.current = current
        }
    }

    /// Typed-current partial that retains ownership of the SELECT header slot.
    public struct HeaderPartial<Current: SQLBuilder.FinalizableItem> {
        let header: Header
        let completed: [SwifQLable]
        let current: Current

        init(header: Header, completed: [SwifQLable], current: Current) {
            self.header = header
            self.completed = completed
            self.current = current
        }
    }

    /// Closed control-flow boundary. No open current / alias continuation.
    public struct FinalizedGroup<Source: SQLBuilder.FinalizableItem> {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    /// Projection history with no open current. May start a new item or append a group.
    public struct Closed {
        let fragments: [SwifQLable]

        init(fragments: [SwifQLable]) {
            self.fragments = fragments
        }
    }

    /// Closed control-flow group that retains ownership of the SELECT header slot.
    public struct HeaderClosed {
        let header: Header
        let fragments: [SwifQLable]

        init(header: Header, fragments: [SwifQLable]) {
            self.header = header
            self.fragments = fragments
        }
    }

    /// Final SELECT statement state. Owns exactly one statement structural frame.
    public struct Result: SwifQLable, SQLBuilder.FinalizableItem {
        private let children: [SwifQLPart]

        init(children: [SwifQLPart]) {
            self.children = children
        }

        public var parts: [SwifQLPart] {
            [SwifQLStructuralFramePart(region: .statement, children: children)]
        }

        public func finalize() -> SwifQLable {
            self
        }
    }

    // MARK: - Expression intake

    public static func buildExpression(
        _ expression: SwifQLable
    ) -> ProjectionItem {
        ProjectionItem(snapshotting: expression.parts)
    }

    public static func buildExpression(
        _ modifier: Distinct
    ) -> Header {
        Header.capturing(modifier)
    }

    public static func buildExpression(
        _ modifier: DistinctOn
    ) -> Header {
        Header.capturing(modifier)
    }

    public static func buildExpression(
        _ request: SQLBuilder.AliasRequest
    ) -> SQLBuilder.AliasRequest {
        request
    }

    // MARK: - Straight-line partial composition

    /// Header-first bodies keep `Header` so `buildOptional(Header?)` matches
    /// the frozen modifier-slot contract.
    public static func buildPartialBlock(
        first: Header
    ) -> Header {
        first
    }

    public static func buildPartialBlock(
        first: ProjectionItem
    ) -> Partial<ProjectionItem> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        first: FinalizedGroup<Source>
    ) -> Closed {
        Closed(fragments: first.fragments)
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        first: FinalizedGroup<Source>?
    ) -> Closed {
        Closed(fragments: first?.fragments ?? [])
    }

    public static func buildPartialBlock<C: SQLBuilder.FinalizableItem>(
        accumulated: Partial<C>,
        next: ProjectionItem
    ) -> Partial<ProjectionItem> {
        Partial(
            completed: accumulated.completed + [accumulated.current.finalize()],
            current: next
        )
    }

    public static func buildPartialBlock<C: SQLBuilder.AliasableItem>(
        accumulated: Partial<C>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<C.Aliased> {
        Partial(
            completed: accumulated.completed,
            current: accumulated.current.addingAlias(next.name)
        )
    }

    public static func buildPartialBlock(
        accumulated: Header,
        next: ProjectionItem
    ) -> HeaderPartial<ProjectionItem> {
        HeaderPartial(header: accumulated, completed: [], current: next)
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        accumulated: Header,
        next: FinalizedGroup<Source>
    ) -> HeaderClosed {
        HeaderClosed(header: accumulated, fragments: next.fragments)
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        accumulated: Header,
        next: FinalizedGroup<Source>?
    ) -> HeaderClosed {
        HeaderClosed(header: accumulated, fragments: next?.fragments ?? [])
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next: ProjectionItem
    ) -> Partial<ProjectionItem> {
        Partial(
            completed: accumulated.fragments,
            current: next
        )
    }

    public static func buildPartialBlock<C: SQLBuilder.FinalizableItem>(
        accumulated: HeaderPartial<C>,
        next: ProjectionItem
    ) -> HeaderPartial<ProjectionItem> {
        HeaderPartial(
            header: accumulated.header,
            completed: accumulated.completed + [accumulated.current.finalize()],
            current: next
        )
    }

    public static func buildPartialBlock<C: SQLBuilder.AliasableItem>(
        accumulated: HeaderPartial<C>,
        next: SQLBuilder.AliasRequest
    ) -> HeaderPartial<C.Aliased> {
        HeaderPartial(
            header: accumulated.header,
            completed: accumulated.completed,
            current: accumulated.current.addingAlias(next.name)
        )
    }

    public static func buildPartialBlock<Current: SQLBuilder.FinalizableItem, Source: SQLBuilder.FinalizableItem>(
        accumulated: HeaderPartial<Current>,
        next: FinalizedGroup<Source>
    ) -> HeaderClosed {
        HeaderClosed(
            header: accumulated.header,
            fragments: accumulated.completed
                + [accumulated.current.finalize()]
                + next.fragments
        )
    }

    public static func buildPartialBlock<Current: SQLBuilder.FinalizableItem, Source: SQLBuilder.FinalizableItem>(
        accumulated: HeaderPartial<Current>,
        next: FinalizedGroup<Source>?
    ) -> HeaderClosed {
        HeaderClosed(
            header: accumulated.header,
            fragments: accumulated.completed
                + [accumulated.current.finalize()]
                + (next?.fragments ?? [])
        )
    }

    public static func buildPartialBlock(
        accumulated: HeaderClosed,
        next: ProjectionItem
    ) -> HeaderPartial<ProjectionItem> {
        HeaderPartial(
            header: accumulated.header,
            completed: accumulated.fragments,
            current: next
        )
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        accumulated: HeaderClosed,
        next: FinalizedGroup<Source>
    ) -> HeaderClosed {
        HeaderClosed(
            header: accumulated.header,
            fragments: accumulated.fragments + next.fragments
        )
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        accumulated: HeaderClosed,
        next: FinalizedGroup<Source>?
    ) -> HeaderClosed {
        HeaderClosed(
            header: accumulated.header,
            fragments: accumulated.fragments + (next?.fragments ?? [])
        )
    }

    public static func buildPartialBlock<C: SQLBuilder.FinalizableItem, Source: SQLBuilder.FinalizableItem>(
        accumulated: Partial<C>,
        next: FinalizedGroup<Source>
    ) -> Closed {
        Closed(
            fragments: accumulated.completed
                + [accumulated.current.finalize()]
                + next.fragments
        )
    }

    public static func buildPartialBlock<C: SQLBuilder.FinalizableItem, Source: SQLBuilder.FinalizableItem>(
        accumulated: Partial<C>,
        next: FinalizedGroup<Source>?
    ) -> Closed {
        Closed(
            fragments: accumulated.completed
                + [accumulated.current.finalize()]
                + (next?.fragments ?? [])
        )
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        accumulated: Closed,
        next: FinalizedGroup<Source>
    ) -> Closed {
        Closed(
            fragments: accumulated.fragments + next.fragments
        )
    }

    public static func buildPartialBlock<Source: SQLBuilder.FinalizableItem>(
        accumulated: Closed,
        next: FinalizedGroup<Source>?
    ) -> Closed {
        Closed(
            fragments: accumulated.fragments + (next?.fragments ?? [])
        )
    }

    // MARK: - Control-flow finalization

    /// Consumes the modifier slot even when the branch is absent.
    public static func buildOptional(
        _ component: Header?
    ) -> Header {
        component ?? Header.absentSlot
    }

    public static func buildOptional<C: SQLBuilder.FinalizableItem>(
        _ component: Partial<C>?
    ) -> FinalizedGroup<C>? {
        component.map { finalizeGroup(from: $0) }
    }

    public static func buildEither(
        first component: Header
    ) -> Header {
        component
    }

    public static func buildEither(
        second component: Header
    ) -> Header {
        component
    }

    public static func buildEither<C: SQLBuilder.FinalizableItem>(
        first component: Partial<C>
    ) -> FinalizedGroup<C> {
        finalizeGroup(from: component)
    }

    public static func buildEither<C: SQLBuilder.FinalizableItem>(
        second component: Partial<C>
    ) -> FinalizedGroup<C> {
        finalizeGroup(from: component)
    }

    public static func buildArray<C: SQLBuilder.FinalizableItem>(
        _ components: [Partial<C>]
    ) -> FinalizedGroup<C> {
        FinalizedGroup(
            fragments: components.flatMap { finalizeGroup(from: $0).fragments }
        )
    }

    // MARK: - Final result

    public static func buildFinalResult(
        _ component: Header
    ) -> Result {
        makeResult(header: component, fragments: [])
    }

    public static func buildFinalResult(
        _ component: Closed
    ) -> Result {
        makeResult(header: nil, fragments: component.fragments)
    }

    public static func buildFinalResult<C: SQLBuilder.FinalizableItem>(
        _ component: Partial<C>
    ) -> Result {
        makeResult(
            header: nil,
            fragments: component.completed + [component.current.finalize()]
        )
    }

    public static func buildFinalResult<C: SQLBuilder.FinalizableItem>(
        _ component: HeaderPartial<C>
    ) -> Result {
        makeResult(
            header: component.header,
            fragments: component.completed + [component.current.finalize()]
        )
    }

    public static func buildFinalResult(
        _ component: HeaderClosed
    ) -> Result {
        makeResult(header: component.header, fragments: component.fragments)
    }

    public static func buildFinalResult<Source: SQLBuilder.FinalizableItem>(
        _ component: FinalizedGroup<Source>
    ) -> Result {
        makeResult(header: nil, fragments: component.fragments)
    }

    public static func buildFinalResult<Source: SQLBuilder.FinalizableItem>(
        _ component: FinalizedGroup<Source>?
    ) -> Result {
        makeResult(header: nil, fragments: component?.fragments ?? [])
    }

    // MARK: - Lowering

    /// Finalize a projection-only partial at a control-flow boundary.
    private static func finalizeGroup<C: SQLBuilder.FinalizableItem>(
        from partial: Partial<C>
    ) -> FinalizedGroup<C> {
        let projections = partial.completed + [partial.current.finalize()]
        return FinalizedGroup(fragments: projections)
    }

    /// Ordinary post-SELECT body parts for a header + projection list.
    private static func postSelectBody(
        header: Header?,
        projections: [SwifQLable]
    ) -> SwifQLable {
        SwifQLableParts(rawParts: bodyParts(header: header, projections: projections))
    }

    private static func bodyParts(
        header: Header?,
        projections: [SwifQLable]
    ) -> [SwifQLPart] {
        var children: [SwifQLPart] = []
        var items: [[SwifQLPart]] = []
        var headerPrefix: [SwifQLPart] = []
        var headerCarries = false
        var hasPresentHeader = false

        if let header {
            switch header.kind {
            case .absent:
                break
            case .present(let prefix, let carries):
                hasPresentHeader = true
                headerPrefix = prefix
                headerCarries = carries
            }
        }

        if hasPresentHeader {
            if headerCarries {
                items.append(headerPrefix)
            } else {
                children.append(contentsOf: headerPrefix)
            }
        }

        for projection in projections {
            items.append(projection.parts)
        }

        for (index, item) in items.enumerated() {
            if index > 0 {
                children.append(o: .comma)
                children.append(o: .space)
            } else if hasPresentHeader && !headerCarries {
                children.appendSpaceIfNeeded()
            }
            children.append(contentsOf: item)
        }

        return children
    }

    private static func makeResult(
        header: Header?,
        fragments: [SwifQLable]
    ) -> Result {
        var children: [SwifQLPart] = []
        children.append(o: .select)
        children.append(o: .space)
        children.append(contentsOf: bodyParts(header: header, projections: fragments))
        return Result(children: children)
    }
}
