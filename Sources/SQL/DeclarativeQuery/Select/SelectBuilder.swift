import Foundation

/// SELECT owns projection separators, postfix aliases, and the canonical leading
/// DISTINCT header. Other children remain ordered SQL fragments.
///
/// Continuation ownership is typed while one projection is open: postfix
/// `Collate`/`AtTimeZone`/`AtLocal` requests and `As` requests attach through
/// typed `buildPartialBlock` transitions, and a closed/aliased item accepts
/// no further continuation. No rendered-token scan is involved.
@resultBuilder
public enum SelectBuilder {
    public protocol CurrentState: SQLBuilder.FinalizableItem {
        func asElements() -> [Element]
    }

    /// Completed result-builder boundary used by optional, branch, and loop composition.
    public protocol ControlFlowComponent {
        var finalizedSelectElements: [Element] { get }
    }

    public protocol AliasableCurrent: CurrentState {
        associatedtype Aliased: CurrentState
        func addingAlias(_ name: String) -> Aliased
    }

    public protocol ContinuableCurrent: CurrentState {
        associatedtype Continued: CurrentState
        func appendingPostfix(_ request: SQLSelectPostfixRequest) -> Continued
    }

    public struct Element {
        enum Kind {
            case projection([SQLPart])
            case modifier([SQLPart], carriesProjection: Bool)
            case alias([SQLPart])
        }

        let kind: Kind
    }

    public struct Result: SQLable, SQLBuilder.FinalizableItem {
        private let children: [SQLPart]

        init(children: [SQLPart]) {
            self.children = children
        }

        public var parts: [SQLPart] {
            [SQLStructuralFramePart(region: .statement, children: children)]
        }

        public func finalize() -> SQLable { self }
    }

    /// One snapshotted projection expression, still open for postfix
    /// continuation and for a postfix alias.
    public struct ProjectionItem: AliasableCurrent, ContinuableCurrent {
        public typealias Aliased = AliasedProjectionItem
        public typealias Continued = ProjectionItem

        private let snapshot: [SQLPart]

        init(snapshotting parts: [SQLPart]) {
            self.snapshot = parts
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: snapshot)
        }

        public func asElements() -> [Element] {
            [Element(kind: .projection(snapshot))]
        }

        public func addingAlias(_ name: String) -> AliasedProjectionItem {
            AliasedProjectionItem(projection: snapshot, alias: name)
        }

        public func appendingPostfix(_ request: SQLSelectPostfixRequest) -> ProjectionItem {
            var parts = snapshot
            parts.appendSpaceIfNeeded()
            parts.append(contentsOf: request.parts)
            return ProjectionItem(snapshotting: parts)
        }
    }

    /// Completed projection with a postfix alias. No further continuation
    /// can legally attach to it.
    public struct AliasedProjectionItem: CurrentState {
        private let projection: [SQLPart]
        private let alias: String

        init(projection: [SQLPart], alias: String) {
            self.projection = projection
            self.alias = alias
        }

        public func finalize() -> SQLable {
            var parts = projection
            parts.append(o: .space, .as, .space)
            parts.append(SQLPartAlias(alias))
            return SQLableParts(rawParts: parts)
        }

        public func asElements() -> [Element] {
            [
                Element(kind: .projection(projection)),
                Element(kind: .alias([SQLPartOperator.as, SQLPartOperator.space, SQLPartAlias(alias)]))
            ]
        }
    }

    /// Leading DISTINCT-family modifier with its projection-ownership flag.
    public struct DistinctItem: AliasableCurrent {
        public typealias Aliased = AliasedDistinctItem

        private let modifierParts: [SQLPart]
        private let carriesProjection: Bool

        init(parts: [SQLPart], carriesProjection: Bool) {
            self.modifierParts = parts
            self.carriesProjection = carriesProjection
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: modifierParts)
        }

        public func asElements() -> [Element] {
            [Element(kind: .modifier(modifierParts, carriesProjection: carriesProjection))]
        }

        public func addingAlias(_ name: String) -> AliasedDistinctItem {
            AliasedDistinctItem(modifierParts: modifierParts, carriesProjection: carriesProjection, alias: name)
        }
    }

    public struct AliasedDistinctItem: CurrentState {
        private let modifierParts: [SQLPart]
        private let carriesProjection: Bool
        private let alias: String

        init(modifierParts: [SQLPart], carriesProjection: Bool, alias: String) {
            self.modifierParts = modifierParts
            self.carriesProjection = carriesProjection
            self.alias = alias
        }

        public func finalize() -> SQLable {
            var parts = modifierParts
            parts.append(o: .space, .as, .space)
            parts.append(SQLPartAlias(alias))
            return SQLableParts(rawParts: parts)
        }

        public func asElements() -> [Element] {
            [
                Element(kind: .modifier(modifierParts, carriesProjection: carriesProjection)),
                Element(kind: .alias([SQLPartOperator.as, SQLPartOperator.space, SQLPartAlias(alias)]))
            ]
        }
    }

    /// `DISTINCT ON (...)` header modifier.
    public struct DistinctOnItem: AliasableCurrent {
        public typealias Aliased = AliasedDistinctOnItem

        private let modifierParts: [SQLPart]

        init(parts: [SQLPart]) {
            self.modifierParts = parts
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: modifierParts)
        }

        public func asElements() -> [Element] {
            [Element(kind: .modifier(modifierParts, carriesProjection: false))]
        }

        public func addingAlias(_ name: String) -> AliasedDistinctOnItem {
            AliasedDistinctOnItem(modifierParts: modifierParts, alias: name)
        }
    }

    public struct AliasedDistinctOnItem: CurrentState {
        private let modifierParts: [SQLPart]
        private let alias: String

        init(modifierParts: [SQLPart], alias: String) {
            self.modifierParts = modifierParts
            self.alias = alias
        }

        public func finalize() -> SQLable {
            var parts = modifierParts
            parts.append(o: .space, .as, .space)
            parts.append(SQLPartAlias(alias))
            return SQLableParts(rawParts: parts)
        }

        public func asElements() -> [Element] {
            [
                Element(kind: .modifier(modifierParts, carriesProjection: false)),
                Element(kind: .alias([SQLPartOperator.as, SQLPartOperator.space, SQLPartAlias(alias)]))
            ]
        }
    }

    public struct Partial<Current: CurrentState>: ControlFlowComponent {
        let completed: [Element]
        let current: Current

        init(completed: [Element], current: Current) {
            self.completed = completed
            self.current = current
        }

        func finalizedElements() -> [Element] {
            completed + current.asElements()
        }

        public var finalizedSelectElements: [Element] { finalizedElements() }
    }

    public struct FinalizedGroup: ControlFlowComponent {
        let elements: [Element]

        init(elements: [Element]) {
            self.elements = elements
        }

        public var finalizedSelectElements: [Element] { elements }
    }

    public struct Closed: ControlFlowComponent {
        let elements: [Element]

        init(elements: [Element]) {
            self.elements = elements
        }

        public var finalizedSelectElements: [Element] { elements }
    }

    public struct EmptyClosed: ControlFlowComponent {
        public var finalizedSelectElements: [Element] { [] }
    }

    // MARK: - Expressions

    public static func buildExpression(_ expression: any SQLable) -> ProjectionItem {
        ProjectionItem(snapshotting: _SQLStructuralComposition.nestedEmbeddingParts(from: expression.parts))
    }

    public static func buildExpression(_ modifier: Distinct) -> DistinctItem {
        DistinctItem(
            parts: modifier.parts,
            carriesProjection: modifier._declarativeCarriesProjection
        )
    }

    public static func buildExpression(_ modifier: DistinctOn) -> DistinctOnItem {
        DistinctOnItem(parts: modifier.parts)
    }

    public static func buildExpression(_ request: SQLBuilder.AliasRequest) -> SQLBuilder.AliasRequest {
        request
    }

    public static func buildExpression(_ request: SQLSelectPostfixRequest) -> SQLSelectPostfixRequest {
        request
    }

    // MARK: - Straight-line composition

    public static func buildBlock() -> EmptyClosed { EmptyClosed() }

    public static func buildPartialBlock(first item: ProjectionItem) -> Partial<ProjectionItem> {
        Partial(completed: [], current: item)
    }

    public static func buildPartialBlock(first item: DistinctItem) -> Partial<DistinctItem> {
        Partial(completed: [], current: item)
    }

    public static func buildPartialBlock(first item: DistinctOnItem) -> Partial<DistinctOnItem> {
        Partial(completed: [], current: item)
    }

    public static func buildPartialBlock(first request: SQLBuilder.AliasRequest) -> Partial<AliasedProjectionItem> {
        Partial(completed: [], current: AliasedProjectionItem(projection: [], alias: request.name))
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next item: ProjectionItem
    ) -> Partial<ProjectionItem> {
        Partial(completed: accumulated.finalizedElements(), current: item)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next item: DistinctItem
    ) -> Partial<DistinctItem> {
        Partial(completed: accumulated.finalizedElements(), current: item)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next item: DistinctOnItem
    ) -> Partial<DistinctOnItem> {
        Partial(completed: accumulated.finalizedElements(), current: item)
    }

    public static func buildPartialBlock<Current: AliasableCurrent>(
        accumulated: Partial<Current>,
        next request: SQLBuilder.AliasRequest
    ) -> Partial<Current.Aliased> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingAlias(request.name))
    }

    public static func buildPartialBlock<Current: ContinuableCurrent>(
        accumulated: Partial<Current>,
        next request: SQLSelectPostfixRequest
    ) -> Partial<Current.Continued> {
        Partial(completed: accumulated.completed, current: accumulated.current.appendingPostfix(request))
    }

    // MARK: - Control-flow boundaries

    public static func buildOptional(_ component: (any ControlFlowComponent)?) -> FinalizedGroup? {
        component.map { FinalizedGroup(elements: $0.finalizedSelectElements) }
    }

    public static func buildEither<Component: ControlFlowComponent>(
        first component: Component
    ) -> FinalizedGroup {
        FinalizedGroup(elements: component.finalizedSelectElements)
    }

    public static func buildEither<Component: ControlFlowComponent>(
        second component: Component
    ) -> FinalizedGroup {
        FinalizedGroup(elements: component.finalizedSelectElements)
    }

    public static func buildArray<Component: ControlFlowComponent>(
        _ components: [Component]
    ) -> FinalizedGroup {
        FinalizedGroup(elements: components.flatMap(\.finalizedSelectElements))
    }

    // MARK: - Ordered list assembly

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next group: FinalizedGroup
    ) -> Closed {
        Closed(elements: accumulated.finalizedElements() + group.elements)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next group: FinalizedGroup?
    ) -> Closed {
        Closed(elements: accumulated.finalizedElements() + (group?.elements ?? []))
    }

    public static func buildPartialBlock(first group: FinalizedGroup) -> Closed {
        Closed(elements: group.elements)
    }

    public static func buildPartialBlock(first group: FinalizedGroup?) -> Closed {
        Closed(elements: group?.elements ?? [])
    }

    public static func buildPartialBlock(first empty: EmptyClosed) -> Closed {
        Closed(elements: [])
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next group: FinalizedGroup
    ) -> Closed {
        Closed(elements: accumulated.elements + group.elements)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next group: FinalizedGroup?
    ) -> Closed {
        Closed(elements: accumulated.elements + (group?.elements ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next empty: EmptyClosed
    ) -> Closed {
        accumulated
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next item: ProjectionItem
    ) -> Partial<ProjectionItem> {
        Partial(completed: accumulated.elements, current: item)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next item: DistinctItem
    ) -> Partial<DistinctItem> {
        Partial(completed: accumulated.elements, current: item)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next item: DistinctOnItem
    ) -> Partial<DistinctOnItem> {
        Partial(completed: accumulated.elements, current: item)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next request: SQLBuilder.AliasRequest
    ) -> Partial<AliasedProjectionItem> {
        Partial(completed: accumulated.elements, current: AliasedProjectionItem(projection: [], alias: request.name))
    }

    // MARK: - Final result

    public static func buildFinalResult<Current: CurrentState>(_ component: Partial<Current>) -> Result {
        makeResult(component.finalizedElements())
    }

    public static func buildFinalResult(_ component: Closed) -> Result {
        makeResult(component.elements)
    }

    public static func buildFinalResult(_ component: FinalizedGroup) -> Result {
        makeResult(component.elements)
    }

    public static func buildFinalResult(_ component: FinalizedGroup?) -> Result {
        makeResult(component?.elements ?? [])
    }

    public static func buildFinalResult(_ component: EmptyClosed) -> Result {
        makeResult([])
    }

    private static func makeResult(_ elements: [Element]) -> Result {
        var children: [SQLPart] = []
        children.append(o: .select, .space)
        var hasListItem = false
        var previousCanOwnAlias = false

        for element in elements {
            switch element.kind {
            case .modifier(let parts, let carriesProjection):
                if !hasListItem {
                    children.appendSpaceIfNeeded()
                    children.append(contentsOf: parts)
                    if carriesProjection {
                        hasListItem = true
                        previousCanOwnAlias = true
                    } else {
                        previousCanOwnAlias = false
                    }
                } else {
                    children.append(o: .comma, .space)
                    var orderedParts = parts
                    if let last = orderedParts.last as? SQLPartOperator, last._value == " " {
                        orderedParts.removeLast()
                    }
                    children.append(contentsOf: orderedParts)
                    previousCanOwnAlias = carriesProjection
                }

            case .projection(let parts):
                guard !parts.isEmpty else {
                    previousCanOwnAlias = false
                    continue
                }
                if hasListItem {
                    children.append(o: .comma, .space)
                } else {
                    children.appendSpaceIfNeeded()
                }
                children.append(contentsOf: parts)
                hasListItem = true
                previousCanOwnAlias = true

            case .alias(let parts):
                if previousCanOwnAlias {
                    children.appendSpaceIfNeeded()
                    children.append(contentsOf: parts)
                } else {
                    if hasListItem {
                        children.append(o: .comma, .space)
                    } else {
                        children.appendSpaceIfNeeded()
                    }
                    children.append(contentsOf: parts)
                    hasListItem = true
                }
                previousCanOwnAlias = false
            }
        }

        return Result(children: children)
    }
}
