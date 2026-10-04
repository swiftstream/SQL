import Foundation

/// Ordered FROM-item composition with local postfix ownership.
@resultBuilder
public enum FromBuilder {
    public protocol CurrentState: SQLBuilder.FinalizableItem {
        func asFromItem() -> FromItem
    }

    /// Completed result-builder boundary used by optional, branch, and loop composition.
    public protocol ControlFlowComponent {
        var finalizedFromItems: [FromItem] { get }
    }

    /// Local rendering identity carried with each completed FROM item.
    public struct FromItem {
        public enum Kind: Sendable {
            case source
            case joinContinuation
        }

        public let kind: Kind
        let parts: [SQLPart]

        init(kind: Kind, parts: [SQLPart]) {
            self.kind = kind
            self.parts = parts
        }
    }

    public protocol SourceState {}

    public protocol AliasableCurrent: CurrentState {
        associatedtype Aliased: CurrentState
        func addingAlias(_ name: String) -> Aliased
    }

    public protocol NestedStatementCurrent: AliasableCurrent {
        var statementParts: [SQLPart] { get }
    }

    public protocol AliasableSourceState: SourceState {
        associatedtype Aliased: SourceState
    }

    public protocol ColumnListSourceState: SourceState {
        associatedtype WithColumns: SourceState
    }

    public enum SourceOpen: AliasableSourceState, ColumnListSourceState {
        public typealias Aliased = SourceAliased
        public typealias WithColumns = SourceAliasedColumns
    }

    public enum SourceAliased: ColumnListSourceState {
        public typealias WithColumns = SourceAliasedColumns
    }

    public enum SourceOrdinality: AliasableSourceState, ColumnListSourceState {
        public typealias Aliased = SourceOrdinalityAliased
        public typealias WithColumns = SourceOrdinalityAliasedColumns
    }

    public enum SourceOrdinalityAliased: ColumnListSourceState {
        public typealias WithColumns = SourceOrdinalityAliasedColumns
    }

    public enum SourceAliasedColumns: SourceState {}
    public enum SourceOrdinalityAliasedColumns: SourceState {}

    /// One snapshotted source with a statically typed local continuation state.
    public struct Source<State: SourceState>: CurrentState {
        let snapshot: [SQLPart]

        init(snapshot: [SQLPart]) {
            self.snapshot = snapshot
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: snapshot)
        }

        public func asFromItem() -> FromItem {
            FromItem(kind: .source, parts: snapshot)
        }
    }

    /// Open direct nested SELECT item before its FROM continuation.
    public struct NestedSelectOpen: NestedStatementCurrent {
        public let statementParts: [SQLPart]

        init(statementParts: [SQLPart]) {
            self.statementParts = statementParts
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: FromBuilder.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Nested SELECT after its FROM/clause fragments, still aliasable.
    public struct NestedStatementOpen: NestedStatementCurrent {
        public let statementParts: [SQLPart]

        init(statementParts: [SQLPart]) {
            self.statementParts = statementParts
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: FromBuilder.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Completed derived item. It cannot accept another alias or clause.
    public struct NestedAliased: CurrentState {
        let statementParts: [SQLPart]
        let alias: String

        init(statementParts: [SQLPart], alias: String) {
            self.statementParts = statementParts
            self.alias = alias
        }

        public func finalize() -> SQLable {
            SQLableParts(rawParts: FromBuilder.derivedParts(statementParts, alias: alias))
        }
    }

    public struct Partial<Current: CurrentState>: ControlFlowComponent {
        let completed: [FromItem]
        let current: Current

        init(completed: [FromItem], current: Current) {
            self.completed = completed
            self.current = current
        }

        func finalizedItems() -> [FromItem] {
            completed + [current.asFromItem()]
        }

        public var finalizedFromItems: [FromItem] { finalizedItems() }
    }

    public struct FinalizedGroup: ControlFlowComponent {
        let items: [FromItem]

        init(items: [FromItem]) {
            self.items = items
        }

        public var finalizedFromItems: [FromItem] { items }
    }

    public struct Closed: ControlFlowComponent {
        let items: [FromItem]

        init(items: [FromItem]) {
            self.items = items
        }

        public var finalizedFromItems: [FromItem] { items }
    }

    public struct EmptyClosed: ControlFlowComponent {
        public var finalizedFromItems: [FromItem] { [] }
    }

    /// Completed FROM clause lowered into one ordinary statement frame.
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

    // MARK: - Expressions

    public static func buildExpression(_ expression: any SQLable) -> Source<SourceOpen> {
        Source(snapshot: _SQLStructuralComposition.nestedEmbeddingParts(from: expression.parts))
    }

    public static func buildExpression(_ expression: SelectBuilder.Result) -> NestedSelectOpen {
        let parts = expression.parts
        let children = (parts.first as? SQLStructuralFramePart)?.children ?? parts
        return NestedSelectOpen(statementParts: children)
    }

    public static func buildExpression(_ expression: Result) -> Result { expression }

    public static func buildExpression(_ request: SQLBuilder.AliasRequest) -> SQLBuilder.AliasRequest {
        request
    }

    public static func buildExpression(_ request: WhereClause) -> WhereClause { request }
    public static func buildExpression(_ request: HavingClause) -> HavingClause { request }
    public static func buildExpression(_ request: QualifyClause) -> QualifyClause { request }
    public static func buildExpression(_ request: GroupByClause) -> GroupByClause { request }
    public static func buildExpression(_ request: OrderByClause) -> OrderByClause { request }
    public static func buildExpression(_ request: LimitClause) -> LimitClause { request }
    public static func buildExpression(_ request: OffsetClause) -> OffsetClause { request }

    public static func buildExpression(_ request: WithOrdinalityRequest) -> WithOrdinalityRequest {
        request
    }

    public static func buildExpression(_ request: FromColumnsRequest) -> FromColumnsRequest {
        request
    }

    // MARK: - Straight-line composition

    public static func buildBlock() -> EmptyClosed { EmptyClosed() }

    public static func buildPartialBlock<State: SourceState>(
        first: Source<State>
    ) -> Partial<Source<State>> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: NestedSelectOpen) -> Partial<NestedSelectOpen> {
        Partial(completed: [], current: first)
    }

    /// A completed FROM fragment may itself be used as a source item.
    public static func buildPartialBlock(first expression: Result) -> Partial<Source<SourceOpen>> {
        Partial(completed: [], current: Source(snapshot: derivedSourceParts(expression)))
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next: Source<SourceOpen>
    ) -> Partial<Source<SourceOpen>> {
        Partial(completed: accumulated.completed + [accumulated.current.asFromItem()], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next: NestedSelectOpen
    ) -> Partial<NestedSelectOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.asFromItem()], current: next)
    }

    /// A direct FROM after SELECT belongs to that nested statement.
    public static func buildPartialBlock(
        accumulated: Partial<NestedSelectOpen>,
        next: Result
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: appendStatementBody(accumulated.current.statementParts, next))
        )
    }

    /// Repeated nested statement fragments retain their literal source order.
    public static func buildPartialBlock(
        accumulated: Partial<NestedStatementOpen>,
        next: Result
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: appendStatementBody(accumulated.current.statementParts, next))
        )
    }

    /// A nested FROM without an immediately preceding SELECT is an ordinary item.
    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next: Result
    ) -> Partial<Source<SourceOpen>> {
        Partial(
            completed: accumulated.completed + [accumulated.current.asFromItem()],
            current: Source(snapshot: derivedSourceParts(next))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: WhereClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                appending: next.predicateParts,
                with: { $0.where($1) }
            ))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: HavingClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                appending: next.predicateParts,
                with: { $0.having($1) }
            ))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: QualifyClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                appending: next.predicateParts,
                with: { $0.qualify($1) }
            ))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: GroupByClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                applying: { _fromAddingGroupBy(next, to: $0) }
            ))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: OrderByClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                applying: { _fromAddingOrderBy(next, to: $0) }
            ))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: LimitClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                applying: { _fromAddingLimit(next, to: $0) }
            ))
        )
    }

    public static func buildPartialBlock<Current: NestedStatementCurrent>(
        accumulated: Partial<Current>,
        next: OffsetClause
    ) -> Partial<NestedStatementOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedStatementOpen(statementParts: _nestedStatementParts(
                accumulated.current.statementParts,
                applying: { _fromAddingOffset(next, to: $0) }
            ))
        )
    }

    public static func buildPartialBlock<Current: AliasableCurrent>(
        accumulated: Partial<Current>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<Current.Aliased> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingAlias(next.name))
    }

    public static func buildPartialBlock(
        accumulated: Partial<Source<SourceOpen>>,
        next: WithOrdinalityRequest
    ) -> Partial<Source<SourceOrdinality>> {
        var parts = accumulated.current.snapshot
        parts.append(o: .space, .custom("WITH"), .space, .custom("ORDINALITY"))
        return Partial(completed: accumulated.completed, current: Source(snapshot: parts))
    }

    public static func buildPartialBlock(
        accumulated: Partial<Source<SourceAliased>>,
        next: WithOrdinalityRequest
    ) -> Partial<Source<SourceOrdinalityAliased>> {
        var parts = accumulated.current.snapshot
        parts.append(o: .space, .custom("WITH"), .space, .custom("ORDINALITY"))
        return Partial(completed: accumulated.completed, current: Source(snapshot: parts))
    }

    public static func buildPartialBlock<Current: ColumnListSourceState>(
        accumulated: Partial<Source<Current>>,
        next: FromColumnsRequest
    ) -> Partial<Source<Current.WithColumns>> {
        var parts = accumulated.current.snapshot
        if !next.names.isEmpty {
            parts.append(o: .space, .openBracket)
            for (index, name) in next.names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SQLPartAlias(name))
            }
            parts.append(o: .closeBracket)
        }
        return Partial(completed: accumulated.completed, current: Source(snapshot: parts))
    }

    // MARK: - Control-flow boundaries

    public static func buildOptional(_ component: (any ControlFlowComponent)?) -> FinalizedGroup? {
        component.map { FinalizedGroup(items: $0.finalizedFromItems) }
    }

    public static func buildEither<Component: ControlFlowComponent>(
        first component: Component
    ) -> FinalizedGroup {
        FinalizedGroup(items: component.finalizedFromItems)
    }

    public static func buildEither<Component: ControlFlowComponent>(
        second component: Component
    ) -> FinalizedGroup {
        FinalizedGroup(items: component.finalizedFromItems)
    }

    public static func buildArray<Component: ControlFlowComponent>(
        _ components: [Component]
    ) -> FinalizedGroup {
        FinalizedGroup(items: components.flatMap(\.finalizedFromItems))
    }

    // MARK: - Ordered list assembly

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next group: FinalizedGroup
    ) -> Closed {
        Closed(items: accumulated.completed + [accumulated.current.asFromItem()] + group.items)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next group: FinalizedGroup?
    ) -> Closed {
        Closed(items: accumulated.completed + [accumulated.current.asFromItem()] + (group?.items ?? []))
    }

    public static func buildPartialBlock(first group: FinalizedGroup) -> Closed {
        Closed(items: group.items)
    }

    public static func buildPartialBlock(first group: FinalizedGroup?) -> Closed {
        Closed(items: group?.items ?? [])
    }

    public static func buildPartialBlock(first empty: EmptyClosed) -> Closed {
        Closed(items: [])
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next group: FinalizedGroup
    ) -> Closed {
        Closed(items: accumulated.items + group.items)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next group: FinalizedGroup?
    ) -> Closed {
        Closed(items: accumulated.items + (group?.items ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next empty: EmptyClosed
    ) -> Closed {
        accumulated
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next: Source<SourceOpen>
    ) -> Partial<Source<SourceOpen>> {
        Partial(completed: accumulated.items, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next: NestedSelectOpen
    ) -> Partial<NestedSelectOpen> {
        Partial(completed: accumulated.items, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next: Result
    ) -> Partial<Source<SourceOpen>> {
        Partial(completed: accumulated.items, current: Source(snapshot: derivedSourceParts(next)))
    }

    // MARK: - Final result

    public static func buildFinalResult<Current: CurrentState>(
        _ component: Partial<Current>
    ) -> Result {
        makeResult(component.finalizedItems())
    }

    public static func buildFinalResult(_ component: Closed) -> Result {
        makeResult(component.items)
    }

    public static func buildFinalResult(_ component: FinalizedGroup) -> Result {
        makeResult(component.items)
    }

    public static func buildFinalResult(_ component: FinalizedGroup?) -> Result {
        makeResult(component?.items ?? [])
    }

    public static func buildFinalResult(_ component: EmptyClosed) -> Result {
        makeResult([])
    }

    private static func makeResult(_ items: [FromItem]) -> Result {
        var children: [SQLPart] = []
        children.append(o: .custom("FROM"), .space)
        var hasItem = false
        for item in items {
            guard !item.parts.isEmpty else { continue }
            if hasItem {
                switch item.kind {
                case .source:
                    children.append(o: .comma, .space)
                case .joinContinuation:
                    children.append(o: .space)
                }
            }
            children.append(contentsOf: item.parts)
            hasItem = true
        }
        return Result(children: children)
    }

    private static func derivedSourceParts(_ result: Result) -> [SQLPart] {
        guard let frame = result.parts.first as? SQLStructuralFramePart else { return result.parts }
        return [SQLPartOperator.openBracket, frame, SQLPartOperator.closeBracket]
    }

    private static func appendStatementBody(_ statementParts: [SQLPart], _ result: Result) -> [SQLPart] {
        let children = (result.parts.first as? SQLStructuralFramePart)?.children ?? result.parts
        var parts = statementParts
        parts.appendSpaceIfNeeded()
        parts.append(contentsOf: children)
        return parts
    }

    fileprivate static func finalizeNestedClause(
        _ statementParts: [SQLPart],
        appending predicateParts: [SQLPart],
        with appendClause: (SQLable, SQLable) -> SQLable
    ) -> [SQLPart] {
        guard !predicateParts.isEmpty else { return statementParts }
        let statement = SQLableParts(parts: [SQLStructuralFramePart(region: .statement, children: statementParts)])
        let appended = appendClause(statement, SQLableParts(rawParts: predicateParts))
        return (appended.parts.first as? SQLStructuralFramePart)?.children ?? appended.parts
    }

    fileprivate static func finalizeNestedClause(
        _ statementParts: [SQLPart],
        applying appendClause: (SQLable) -> SQLable
    ) -> [SQLPart] {
        let statement = SQLableParts(parts: [SQLStructuralFramePart(region: .statement, children: statementParts)])
        let appended = appendClause(statement)
        return (appended.parts.first as? SQLStructuralFramePart)?.children ?? appended.parts
    }

    private static func _fromAddingGroupBy(_ request: GroupByClause, to statement: SQLable) -> SQLable {
        let expressions = request.expressionParts
            .filter { !$0.isEmpty }
            .map { SQLableParts(rawParts: $0) as SQLable }
        guard !expressions.isEmpty else { return statement }
        return statement.groupBy(expressions)
    }

    private static func _fromAddingOrderBy(_ request: OrderByClause, to statement: SQLable) -> SQLable {
        guard !request.items.isEmpty else { return statement }
        return statement.orderBy(request.items)
    }

    private static func _fromAddingLimit(_ request: LimitClause, to statement: SQLable) -> SQLable {
        guard !request.countParts.isEmpty else { return statement }
        return statement.limit(SQLableParts(rawParts: request.countParts))
    }

    private static func _fromAddingOffset(_ request: OffsetClause, to statement: SQLable) -> SQLable {
        guard !request.countParts.isEmpty else { return statement }
        return statement.offset(SQLableParts(rawParts: request.countParts))
    }

    private static func derivedParts(_ statementParts: [SQLPart], alias: String?) -> [SQLPart] {
        var parts: [SQLPart] = [SQLPartOperator.openBracket]
        parts.append(SQLStructuralFramePart(region: .statement, children: statementParts))
        parts.append(SQLPartOperator.closeBracket)
        if let alias {
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(SQLPartAlias(alias))
        }
        return parts
    }
}

public extension FromBuilder.CurrentState {
    func asFromItem() -> FromBuilder.FromItem {
        FromBuilder.FromItem(kind: .source, parts: finalize().parts)
    }
}

extension FromBuilder.Source: FromBuilder.AliasableCurrent where State: FromBuilder.AliasableSourceState {
    public typealias Aliased = FromBuilder.Source<State.Aliased>

    public func addingAlias(_ name: String) -> Aliased {
        var parts = snapshot
        parts.append(o: .space, .custom("AS"), .space)
        parts.append(SQLPartAlias(name))
        return FromBuilder.Source<State.Aliased>(snapshot: parts)
    }
}

private func _nestedStatementParts(
    _ statementParts: [SQLPart],
    appending predicateParts: [SQLPart],
    with appendClause: (SQLable, SQLable) -> SQLable
) -> [SQLPart] {
    FromBuilder.finalizeNestedClause(statementParts, appending: predicateParts, with: appendClause)
}

private func _nestedStatementParts(
    _ statementParts: [SQLPart],
    applying appendClause: (SQLable) -> SQLable
) -> [SQLPart] {
    FromBuilder.finalizeNestedClause(statementParts, applying: appendClause)
}
