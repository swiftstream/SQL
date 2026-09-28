import Foundation

/// Typed FROM source and derived-item construction.
@resultBuilder
public enum FromBuilder {
    public protocol CurrentState: SQLBuilder.FinalizableItem {}

    /// Static proof dimensions carried by a FROM fragment.
    public protocol RootGuarantee {}
    public protocol FragmentRole {}

    /// Combines independent root-guarantee and fragment-role proofs.
    public protocol AttachmentState {
        associatedtype Guarantee: RootGuarantee
        associatedtype Role: FragmentRole
    }

    public enum NoLeftSource: RootGuarantee {}
    public enum HasLeftSource: RootGuarantee {}
    public enum SourceList: FragmentRole {}
    public enum JoinContinuationOnly: FragmentRole {}

    public struct Fragment<G: RootGuarantee, R: FragmentRole>: AttachmentState {
        public typealias Guarantee = G
        public typealias Role = R
    }

    /// Structural separator metadata for a JOIN item finalized across a branch.
    struct JoinContinuationPart: SwifQLPart {}

    public protocol SourceListBranch {
        func finalizeSourceListBranch() -> [[SwifQLPart]]
    }

    public protocol JoinContinuationBranch {
        func finalizeJoinContinuationBranch() -> [[SwifQLPart]]
    }

    public protocol SourceState {}

    public protocol AliasableCurrent: CurrentState {
        associatedtype Aliased: CurrentState
        func addingAlias(_ name: String) -> Aliased
    }

    /// Open nested SELECT states expose their structural statement children to
    /// typed clause continuations without exposing a general mutable owner.
    public protocol NestedStatementCurrent: AliasableCurrent {
        var statementParts: [SwifQLPart] { get }
    }

    public protocol NestedGroupAttachable: NestedStatementCurrent {}
    public protocol NestedOrderByAttachable: NestedStatementCurrent {}
    public protocol NestedLimitAttachable: NestedStatementCurrent {}
    public protocol NestedOffsetAttachable: NestedStatementCurrent {}

    public protocol AliasableSourceState: SourceState {
        associatedtype Aliased: SourceState
    }

    public protocol ColumnListSourceState: SourceState {
        associatedtype WithColumns: SourceState
    }

    public enum SourceOpen: AliasableSourceState {
        public typealias Aliased = SourceAliased
    }

    public enum SourceAliased: ColumnListSourceState {
        public typealias WithColumns = SourceAliasedColumns
    }

    public enum SourceOrdinality: AliasableSourceState {
        public typealias Aliased = SourceOrdinalityAliased
    }

    public enum SourceOrdinalityAliased: ColumnListSourceState {
        public typealias WithColumns = SourceOrdinalityAliasedColumns
    }

    public enum SourceAliasedColumns: SourceState {}
    public enum SourceOrdinalityAliasedColumns: SourceState {}

    /// One snapshotted source with a statically typed continuation state.
    public struct Source<State: SourceState>: CurrentState {
        let snapshot: [SwifQLPart]

        init(snapshot: [SwifQLPart]) {
            self.snapshot = snapshot
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: snapshot)
        }

    }

    /// Open direct nested SELECT item before its FROM continuation.
    public struct NestedSelectOpen: NestedGroupAttachable, NestedOrderByAttachable, NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        init(statementParts: [SwifQLPart]) {
            self.statementParts = statementParts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: Self.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after its same-name FROM continuation.
    public struct NestedFromOpen: NestedGroupAttachable, NestedOrderByAttachable, NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        init(statementParts: [SwifQLPart]) {
            self.statementParts = statementParts
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after WHERE and still open for later clauses or As.
    public struct NestedWhereOpen: NestedGroupAttachable, NestedOrderByAttachable, NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after GROUP BY and still open for later clauses or As.
    public struct NestedGroupOpen: NestedOrderByAttachable, NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after HAVING and still open for QUALIFY or As.
    public struct NestedHavingOpen: NestedOrderByAttachable, NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after QUALIFY and still open for As.
    public struct NestedQualifyOpen: NestedOrderByAttachable, NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after ORDER BY and still open for LIMIT/OFFSET or As.
    public struct NestedOrderOpen: NestedLimitAttachable, NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after LIMIT and still open for OFFSET or As.
    public struct NestedLimitOpen: NestedOffsetAttachable {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Direct nested SELECT after OFFSET and still open for As.
    public struct NestedOffsetOpen: AliasableCurrent {
        public let statementParts: [SwifQLPart]

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: nil))
        }

        public func addingAlias(_ name: String) -> NestedAliased {
            NestedAliased(statementParts: statementParts, alias: name)
        }
    }

    /// Completed derived item. It cannot accept another alias or clause.
    public struct NestedAliased: CurrentState {
        let statementParts: [SwifQLPart]
        let alias: String

        init(statementParts: [SwifQLPart], alias: String) {
            self.statementParts = statementParts
            self.alias = alias
        }

        public func finalize() -> SwifQLable {
            SwifQLableParts(rawParts: NestedSelectOpen.derivedParts(statementParts, alias: alias))
        }
    }

    public struct Partial<Attachment: AttachmentState, Current: CurrentState> {
        let completed: [[SwifQLPart]]
        let current: Current

        init(completed: [[SwifQLPart]], current: Current) {
            self.completed = completed
            self.current = current
        }

        func finalizedFragments() -> [[SwifQLPart]] {
            completed + [current.finalize().parts]
        }
    }

    public struct FinalizedGroup<Attachment: AttachmentState> {
        let fragments: [[SwifQLPart]]

        init(fragments: [[SwifQLPart]]) {
            self.fragments = fragments
        }
    }

    public struct Closed<Attachment: AttachmentState> {
        let fragments: [[SwifQLPart]]

        init(fragments: [[SwifQLPart]]) {
            self.fragments = fragments
        }
    }

    /// Statically written-empty FROM syntax, kept outside source-list finalization.
    public struct EmptyClosed {}

    /// Completed FROM clause lowered into one ordinary statement frame.
    public struct Result: SwifQLable, SQLBuilder.FinalizableItem {
        private let children: [SwifQLPart]

        init(children: [SwifQLPart]) {
            self.children = children
        }

        public var parts: [SwifQLPart] {
            [SwifQLStructuralFramePart(region: .statement, children: children)]
        }

        public func finalize() -> SwifQLable { self }
    }

    /// Completed FROM clause retaining typed source fragments for an outer JOIN owner.
    public struct GuaranteedResult: SwifQLable, SQLBuilder.FinalizableItem {
        let children: [SwifQLPart]
        let itemFragments: [[SwifQLPart]]

        init(children: [SwifQLPart], itemFragments: [[SwifQLPart]]) {
            self.children = children
            self.itemFragments = itemFragments
        }

        public var parts: [SwifQLPart] {
            [SwifQLStructuralFramePart(region: .statement, children: children)]
        }

        public func finalize() -> SwifQLable { self }
    }

    // MARK: - Expressions

    public static func buildExpression(_ expression: GuaranteedResult) -> Result {
        Result(children: expression.children)
    }

    public static func buildExpression(_ expression: SwifQLable) -> Source<SourceOpen> {
        let parts = expression.parts
        if let frame = parts.first as? SwifQLStructuralFramePart,
           frame.region == .statement {
            var derived: [SwifQLPart] = []
            derived.append(o: .openBracket)
            derived.append(frame)
            derived.append(o: .closeBracket)
            return Source(snapshot: derived)
        }
        return Source(snapshot: parts)
    }

    public static func buildExpression(_ expression: SelectBuilder.Result) -> NestedSelectOpen {
        let parts = expression.parts
        let children = (parts.first as? SwifQLStructuralFramePart)?.children ?? parts
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
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<State>> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: NestedSelectOpen) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: JoinBuilder.JoinOpen) -> Partial<Fragment<NoLeftSource, JoinContinuationOnly>, JoinBuilder.JoinOpen> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: JoinBuilder.JoinSourceAliased) -> Partial<Fragment<NoLeftSource, JoinContinuationOnly>, JoinBuilder.JoinSourceAliased> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen>,
        next: Result
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen> {
        let parts = next.parts
        let children = (parts.first as? SwifQLStructuralFramePart)?.children ?? parts
        var statementParts = accumulated.current.statementParts
        statementParts.appendSpaceIfNeeded()
        statementParts.append(contentsOf: children)
        return Partial(completed: accumulated.completed, current: NestedFromOpen(statementParts: statementParts))
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen>,
        next: WhereClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedWhereOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.where($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen>,
        next: WhereClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedWhereOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.where($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen>,
        next: HavingClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedHavingOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.having($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen>,
        next: HavingClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedHavingOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.having($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedGroupAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: GroupByClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedGroupOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedGroupOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingGroupBy(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedGroupOpen>,
        next: HavingClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedHavingOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.having($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedGroupOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedOrderByAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: OrderByClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedOrderOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedOrderOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingOrderBy(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedLimitAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: LimitClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedLimitOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedLimitOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingLimit(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedOffsetAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: OffsetClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedOffsetOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedOffsetOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingOffset(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock<Attachment: AttachmentState, Current: AliasableCurrent>(
        accumulated: Partial<Attachment, Current>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<Attachment, Current.Aliased> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingAlias(next.name))
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>>,
        next: WithOrdinalityRequest
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOrdinality>> {
        var parts = accumulated.current.snapshot
        parts.append(o: .space, .custom("WITH"), .space, .custom("ORDINALITY"))
        return Partial(completed: accumulated.completed, current: Source<SourceOrdinality>(snapshot: parts))
    }

    public static func buildPartialBlock<Current: ColumnListSourceState>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Source<Current>>,
        next: FromColumnsRequest
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<Current.WithColumns>> {
        var parts = accumulated.current.snapshot
        if !next.names.isEmpty {
            parts.append(o: .space, .openBracket)
            for (index, name) in next.names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartAlias(name))
            }
            parts.append(o: .closeBracket)
        }
        return Partial(completed: accumulated.completed, current: Source<Current.WithColumns>(snapshot: parts))
    }

    // A guaranteed source chain may absorb either role; JOIN continuations attach
    // to its current source while source-list groups remain comma-separated items.
    public static func buildPartialBlock<Current: CurrentState, Role: FragmentRole>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, Role>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState, Role: FragmentRole>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<HasLeftSource, Role>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState, Role: FragmentRole>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, Role>>?
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + (next?.fragments ?? []))
    }

    // Source-list prefixes can be followed by source-list control-flow groups,
    // but a continuation-only prefix cannot be rescued by any later source.
    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, JoinContinuationOnly>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>
    ) -> Closed<Fragment<NoLeftSource, JoinContinuationOnly>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock(
        first: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: first.fragments)
    }

    public static func buildPartialBlock(
        first: FinalizedGroup<Fragment<NoLeftSource, SourceList>>?
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: first?.fragments ?? [])
    }

    public static func buildPartialBlock(
        first: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>?
    ) -> Closed<Fragment<NoLeftSource, JoinContinuationOnly>> {
        Closed(fragments: first?.fragments ?? [])
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>?
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>?
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>?
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, JoinContinuationOnly>>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>
    ) -> Closed<Fragment<NoLeftSource, JoinContinuationOnly>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.fragments, current: next)
    }

    // No source-start overload exists for Closed<NoLeftSource + JoinContinuationOnly>.

    // MARK: - Control-flow boundaries

    public static func buildOptional(
        _ component: (any SourceListBranch)?
    ) -> FinalizedGroup<Fragment<NoLeftSource, SourceList>>? {
        component.map { FinalizedGroup(fragments: $0.finalizeSourceListBranch()) }
    }

    public static func buildOptional(
        _ component: (any JoinContinuationBranch)?
    ) -> FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>? {
        component.map { FinalizedGroup(fragments: $0.finalizeJoinContinuationBranch()) }
    }

    public static func buildEither<Guarantee: RootGuarantee, Role: FragmentRole, Current: CurrentState>(
        first component: Partial<Fragment<Guarantee, Role>, Current>
    ) -> FinalizedGroup<Fragment<Guarantee, Role>> {
        finalizeGroup(component)
    }

    public static func buildEither<Guarantee: RootGuarantee, Role: FragmentRole, Current: CurrentState>(
        second component: Partial<Fragment<Guarantee, Role>, Current>
    ) -> FinalizedGroup<Fragment<Guarantee, Role>> {
        finalizeGroup(component)
    }

    public static func buildArray<Guarantee: RootGuarantee, Role: FragmentRole, Current: CurrentState>(
        _ components: [Partial<Fragment<Guarantee, Role>, Current>]
    ) -> FinalizedGroup<Fragment<NoLeftSource, Role>> {
        FinalizedGroup(fragments: components.flatMap { finalizeGroup($0).fragments })
    }

    // MARK: - Final result

    public static func buildFinalResult(_ component: Closed<Fragment<HasLeftSource, SourceList>>) -> Result {
        makeResult(component.fragments)
    }

    public static func buildFinalResult<Current: CurrentState>(
        _ component: Partial<Fragment<HasLeftSource, SourceList>, Current>
    ) -> Result {
        makeResult(component.completed + [component.current.finalize().parts])
    }

    public static func buildFinalResult(
        _ component: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Result {
        makeResult(component.fragments)
    }

    public static func buildFinalResult(
        _ component: FinalizedGroup<Fragment<HasLeftSource, SourceList>>?
    ) -> Result {
        makeResult(component?.fragments ?? [])
    }

    public static func buildFinalResult(
        _ component: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Result {
        makeResult(component.fragments)
    }

    public static func buildFinalResult(
        _ component: Closed<Fragment<NoLeftSource, SourceList>>
    ) -> Result {
        makeResult(component.fragments)
    }

    private static func finalizeGroup<Attachment: AttachmentState, Current: CurrentState>(
        _ component: Partial<Attachment, Current>
    ) -> FinalizedGroup<Attachment> {
        FinalizedGroup(fragments: component.finalizedFragments())
    }

    private static func makeResult(_ items: [[SwifQLPart]]) -> Result {
        Result(children: assemble(items))
    }

    /// Shared FROM item assembler for legacy and guaranteed result paths.
    static func assemble(_ items: [[SwifQLPart]]) -> [SwifQLPart] {
        var children: [SwifQLPart] = []
        children.append(o: .custom("FROM"), .space)
        var hasItem = false
        for item in items {
            let continuesPrevious = item.first is JoinContinuationPart
            let content = continuesPrevious ? Array(item.dropFirst()) : item
            guard !content.isEmpty else { continue }
            if hasItem {
                children.append(o: continuesPrevious ? .space : .comma)
                if !continuesPrevious { children.append(o: .space) }
            }
            children.append(contentsOf: content)
            hasItem = true
        }
        return children
    }
}


@resultBuilder
public enum GuaranteedFromBuilder {
    // Reuse the established FromBuilder grammar states. This builder adds only
    // a guaranteed final result; it does not introduce parallel public states.
    public typealias RootGuarantee = FromBuilder.RootGuarantee
    public typealias FragmentRole = FromBuilder.FragmentRole
    public typealias AttachmentState = FromBuilder.AttachmentState
    public typealias NoLeftSource = FromBuilder.NoLeftSource
    public typealias HasLeftSource = FromBuilder.HasLeftSource
    public typealias SourceList = FromBuilder.SourceList
    public typealias JoinContinuationOnly = FromBuilder.JoinContinuationOnly
    public typealias Fragment<G: RootGuarantee, R: FragmentRole> = FromBuilder.Fragment<G, R>
    typealias JoinContinuationPart = FromBuilder.JoinContinuationPart
    public typealias SourceListBranch = FromBuilder.SourceListBranch
    public typealias JoinContinuationBranch = FromBuilder.JoinContinuationBranch
    public typealias SourceState = FromBuilder.SourceState
    public typealias CurrentState = FromBuilder.CurrentState
    public typealias AliasableCurrent = FromBuilder.AliasableCurrent
    public typealias NestedStatementCurrent = FromBuilder.NestedStatementCurrent
    public typealias NestedGroupAttachable = FromBuilder.NestedGroupAttachable
    public typealias NestedOrderByAttachable = FromBuilder.NestedOrderByAttachable
    public typealias NestedLimitAttachable = FromBuilder.NestedLimitAttachable
    public typealias NestedOffsetAttachable = FromBuilder.NestedOffsetAttachable
    public typealias AliasableSourceState = FromBuilder.AliasableSourceState
    public typealias ColumnListSourceState = FromBuilder.ColumnListSourceState
    public typealias SourceOpen = FromBuilder.SourceOpen
    public typealias SourceAliased = FromBuilder.SourceAliased
    public typealias SourceOrdinality = FromBuilder.SourceOrdinality
    public typealias SourceOrdinalityAliased = FromBuilder.SourceOrdinalityAliased
    public typealias SourceAliasedColumns = FromBuilder.SourceAliasedColumns
    public typealias SourceOrdinalityAliasedColumns = FromBuilder.SourceOrdinalityAliasedColumns
    public typealias Source<State: SourceState> = FromBuilder.Source<State>
    public typealias NestedSelectOpen = FromBuilder.NestedSelectOpen
    public typealias NestedFromOpen = FromBuilder.NestedFromOpen
    public typealias NestedWhereOpen = FromBuilder.NestedWhereOpen
    public typealias NestedGroupOpen = FromBuilder.NestedGroupOpen
    public typealias NestedHavingOpen = FromBuilder.NestedHavingOpen
    public typealias NestedQualifyOpen = FromBuilder.NestedQualifyOpen
    public typealias NestedOrderOpen = FromBuilder.NestedOrderOpen
    public typealias NestedLimitOpen = FromBuilder.NestedLimitOpen
    public typealias NestedOffsetOpen = FromBuilder.NestedOffsetOpen
    public typealias NestedAliased = FromBuilder.NestedAliased
    public typealias Partial<A: AttachmentState, C: CurrentState> = FromBuilder.Partial<A, C>
    public typealias FinalizedGroup<A: AttachmentState> = FromBuilder.FinalizedGroup<A>
    public typealias Closed<A: AttachmentState> = FromBuilder.Closed<A>
    public typealias EmptyClosed = FromBuilder.EmptyClosed
    public typealias Result = FromBuilder.Result

    // MARK: - Expressions

    public static func buildExpression(_ expression: FromBuilder.GuaranteedResult) -> Result {
        Result(children: expression.children)
    }

    public static func buildExpression(_ expression: SwifQLable) -> Source<SourceOpen> {
        let parts = expression.parts
        if let frame = parts.first as? SwifQLStructuralFramePart,
           frame.region == .statement {
            var derived: [SwifQLPart] = []
            derived.append(o: .openBracket)
            derived.append(frame)
            derived.append(o: .closeBracket)
            return Source(snapshot: derived)
        }
        return Source(snapshot: parts)
    }

    public static func buildExpression(_ expression: SelectBuilder.Result) -> NestedSelectOpen {
        let parts = expression.parts
        let children = (parts.first as? SwifQLStructuralFramePart)?.children ?? parts
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
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<State>> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: NestedSelectOpen) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: JoinBuilder.JoinOpen) -> Partial<Fragment<NoLeftSource, JoinContinuationOnly>, JoinBuilder.JoinOpen> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: JoinBuilder.JoinSourceAliased) -> Partial<Fragment<NoLeftSource, JoinContinuationOnly>, JoinBuilder.JoinSourceAliased> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize().parts], current: next)
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen>,
        next: Result
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen> {
        let parts = next.parts
        let children = (parts.first as? SwifQLStructuralFramePart)?.children ?? parts
        var statementParts = accumulated.current.statementParts
        statementParts.appendSpaceIfNeeded()
        statementParts.append(contentsOf: children)
        return Partial(completed: accumulated.completed, current: NestedFromOpen(statementParts: statementParts))
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen>,
        next: WhereClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedWhereOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.where($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen>,
        next: WhereClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedWhereOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.where($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen>,
        next: HavingClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedHavingOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.having($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen>,
        next: HavingClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedHavingOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.having($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedFromOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedWhereOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedGroupAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: GroupByClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedGroupOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedGroupOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingGroupBy(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedGroupOpen>,
        next: HavingClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedHavingOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.having($1) }
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, NestedGroupOpen>,
        next: QualifyClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedQualifyOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    appending: next.predicateParts,
                    with: { $0.qualify($1) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedOrderByAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: OrderByClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedOrderOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedOrderOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingOrderBy(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedLimitAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: LimitClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedLimitOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedLimitOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingLimit(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock<Current: NestedOffsetAttachable>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: OffsetClause
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedOffsetOpen> {
        Partial(
            completed: accumulated.completed,
            current: NestedOffsetOpen(
                statementParts: _nestedStatementParts(
                    accumulated.current.statementParts,
                    applying: { _fromAddingOffset(next, to: $0) }
                )
            )
        )
    }

    public static func buildPartialBlock<Attachment: AttachmentState, Current: AliasableCurrent>(
        accumulated: Partial<Attachment, Current>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<Attachment, Current.Aliased> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingAlias(next.name))
    }

    public static func buildPartialBlock(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>>,
        next: WithOrdinalityRequest
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOrdinality>> {
        var parts = accumulated.current.snapshot
        parts.append(o: .space, .custom("WITH"), .space, .custom("ORDINALITY"))
        return Partial(completed: accumulated.completed, current: Source<SourceOrdinality>(snapshot: parts))
    }

    public static func buildPartialBlock<Current: ColumnListSourceState>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Source<Current>>,
        next: FromColumnsRequest
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<Current.WithColumns>> {
        var parts = accumulated.current.snapshot
        if !next.names.isEmpty {
            parts.append(o: .space, .openBracket)
            for (index, name) in next.names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartAlias(name))
            }
            parts.append(o: .closeBracket)
        }
        return Partial(completed: accumulated.completed, current: Source<Current.WithColumns>(snapshot: parts))
    }

    // A guaranteed source chain may absorb either role; JOIN continuations attach
    // to its current source while source-list groups remain comma-separated items.
    public static func buildPartialBlock<Current: CurrentState, Role: FragmentRole>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, Role>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState, Role: FragmentRole>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<HasLeftSource, Role>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState, Role: FragmentRole>(
        accumulated: Partial<Fragment<HasLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, Role>>?
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + (next?.fragments ?? []))
    }

    // Source-list prefixes can be followed by source-list control-flow groups,
    // but a continuation-only prefix cannot be rescued by any later source.
    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, SourceList>, Current>,
        next: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Fragment<NoLeftSource, JoinContinuationOnly>, Current>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>
    ) -> Closed<Fragment<NoLeftSource, JoinContinuationOnly>> {
        Closed(fragments: accumulated.completed + [accumulated.current.finalize().parts] + next.fragments)
    }

    public static func buildPartialBlock(
        first: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: first.fragments)
    }

    public static func buildPartialBlock(
        first: FinalizedGroup<Fragment<NoLeftSource, SourceList>>?
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: first?.fragments ?? [])
    }

    public static func buildPartialBlock(
        first: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>?
    ) -> Closed<Fragment<NoLeftSource, JoinContinuationOnly>> {
        Closed(fragments: first?.fragments ?? [])
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>?
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>?
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> Closed<Fragment<HasLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: FinalizedGroup<Fragment<NoLeftSource, SourceList>>?
    ) -> Closed<Fragment<NoLeftSource, SourceList>> {
        Closed(fragments: accumulated.fragments + (next?.fragments ?? []))
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, JoinContinuationOnly>>,
        next: FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>
    ) -> Closed<Fragment<NoLeftSource, JoinContinuationOnly>> {
        Closed(fragments: accumulated.fragments + next.fragments)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<HasLeftSource, SourceList>>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: Source<SourceOpen>
    ) -> Partial<Fragment<HasLeftSource, SourceList>, Source<SourceOpen>> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed<Fragment<NoLeftSource, SourceList>>,
        next: NestedSelectOpen
    ) -> Partial<Fragment<HasLeftSource, SourceList>, NestedSelectOpen> {
        Partial(completed: accumulated.fragments, current: next)
    }

    // No source-start overload exists for Closed<NoLeftSource + JoinContinuationOnly>.

    // MARK: - Control-flow boundaries

    public static func buildOptional(
        _ component: (any SourceListBranch)?
    ) -> FinalizedGroup<Fragment<NoLeftSource, SourceList>>? {
        component.map { FinalizedGroup(fragments: $0.finalizeSourceListBranch()) }
    }

    public static func buildOptional(
        _ component: (any JoinContinuationBranch)?
    ) -> FinalizedGroup<Fragment<NoLeftSource, JoinContinuationOnly>>? {
        component.map { FinalizedGroup(fragments: $0.finalizeJoinContinuationBranch()) }
    }

    public static func buildEither<Guarantee: RootGuarantee, Role: FragmentRole, Current: CurrentState>(
        first component: Partial<Fragment<Guarantee, Role>, Current>
    ) -> FinalizedGroup<Fragment<Guarantee, Role>> {
        finalizeGroup(component)
    }

    public static func buildEither<Guarantee: RootGuarantee, Role: FragmentRole, Current: CurrentState>(
        second component: Partial<Fragment<Guarantee, Role>, Current>
    ) -> FinalizedGroup<Fragment<Guarantee, Role>> {
        finalizeGroup(component)
    }

    public static func buildArray<Guarantee: RootGuarantee, Role: FragmentRole, Current: CurrentState>(
        _ components: [Partial<Fragment<Guarantee, Role>, Current>]
    ) -> FinalizedGroup<Fragment<NoLeftSource, Role>> {
        FinalizedGroup(fragments: components.flatMap { finalizeGroup($0).fragments })
    }

    // MARK: - Final result

    public static func buildFinalResult(_ component: Closed<Fragment<HasLeftSource, SourceList>>) -> FromBuilder.GuaranteedResult {
        makeGuaranteedResult(component.fragments)
    }

    public static func buildFinalResult<Current: CurrentState>(
        _ component: Partial<Fragment<HasLeftSource, SourceList>, Current>
    ) -> FromBuilder.GuaranteedResult {
        makeGuaranteedResult(component.completed + [component.current.finalize().parts])
    }

    public static func buildFinalResult(
        _ component: FinalizedGroup<Fragment<HasLeftSource, SourceList>>
    ) -> FromBuilder.GuaranteedResult {
        makeGuaranteedResult(component.fragments)
    }

    public static func buildFinalResult(
        _ component: FinalizedGroup<Fragment<HasLeftSource, SourceList>>?
    ) -> FromBuilder.GuaranteedResult {
        makeGuaranteedResult(component?.fragments ?? [])
    }

    public static func buildFinalResult(
        _ component: FinalizedGroup<Fragment<NoLeftSource, SourceList>>
    ) -> Result {
        makeResult(component.fragments)
    }

    public static func buildFinalResult(
        _ component: Closed<Fragment<NoLeftSource, SourceList>>
    ) -> Result {
        makeResult(component.fragments)
    }

    private static func finalizeGroup<Attachment: AttachmentState, Current: CurrentState>(
        _ component: Partial<Attachment, Current>
    ) -> FinalizedGroup<Attachment> {
        FinalizedGroup(fragments: component.finalizedFragments())
    }

    private static func makeResult(_ items: [[SwifQLPart]]) -> Result {
        var children: [SwifQLPart] = []
        children.append(o: .custom("FROM"), .space)
        var hasItem = false
        for item in items {
            let continuesPrevious = item.first is JoinContinuationPart
            let content = continuesPrevious ? Array(item.dropFirst()) : item
            guard !content.isEmpty else { continue }
            if hasItem {
                children.append(o: continuesPrevious ? .space : .comma)
                if !continuesPrevious { children.append(o: .space) }
            }
            children.append(contentsOf: content)
            hasItem = true
        }
        return Result(children: children)
    }

    private static func makeGuaranteedResult(_ items: [[SwifQLPart]]) -> FromBuilder.GuaranteedResult {
        FromBuilder.GuaranteedResult(children: FromBuilder.assemble(items), itemFragments: items)
    }

}

extension FromBuilder.Source: FromBuilder.AliasableCurrent where State: FromBuilder.AliasableSourceState {
    public typealias Aliased = FromBuilder.Source<State.Aliased>

    public func addingAlias(_ name: String) -> Aliased {
        var parts = snapshot
        parts.append(o: .space, .custom("AS"), .space)
        parts.append(SwifQLPartAlias(name))
        return FromBuilder.Source<State.Aliased>(snapshot: parts)
    }
}

private extension FromBuilder.NestedSelectOpen {
    static func derivedParts(_ statementParts: [SwifQLPart], alias: String?) -> [SwifQLPart] {
        var parts: [SwifQLPart] = []
        parts.append(o: .openBracket)
        parts.append(SwifQLStructuralFramePart(region: .statement, children: statementParts))
        parts.append(o: .closeBracket)
        if let alias {
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(SwifQLPartAlias(alias))
        }
        return parts
    }
}

private func _nestedStatementParts(
    _ statementParts: [SwifQLPart],
    appending predicateParts: [SwifQLPart],
    with appendClause: (SwifQLable, SwifQLable) -> SwifQLable
) -> [SwifQLPart] {
    guard !predicateParts.isEmpty else { return statementParts }

    let frame = SwifQLStructuralFramePart(region: .statement, children: statementParts)
    let statement = SwifQLableParts(parts: [frame])
    let appended = appendClause(statement, SwifQLableParts(rawParts: predicateParts))
    return (appended.parts.first as? SwifQLStructuralFramePart)?.children ?? appended.parts
}

private func _nestedStatementParts(
    _ statementParts: [SwifQLPart],
    applying appendClause: (SwifQLable) -> SwifQLable
) -> [SwifQLPart] {
    let frame = SwifQLStructuralFramePart(region: .statement, children: statementParts)
    let statement = SwifQLableParts(parts: [frame])
    let appended = appendClause(statement)
    return (appended.parts.first as? SwifQLStructuralFramePart)?.children ?? appended.parts
}

private func _fromAddingGroupBy(_ request: GroupByClause, to statement: SwifQLable) -> SwifQLable {
    let expressions = request.expressionParts
        .filter { !$0.isEmpty }
        .map { SwifQLableParts(rawParts: $0) as SwifQLable }
    guard !expressions.isEmpty else { return statement }
    return statement.groupBy(expressions)
}

private func _fromAddingOrderBy(_ request: OrderByClause, to statement: SwifQLable) -> SwifQLable {
    guard !request.items.isEmpty else { return statement }
    return statement.orderBy(request.items)
}

private func _fromAddingLimit(_ request: LimitClause, to statement: SwifQLable) -> SwifQLable {
    guard !request.countParts.isEmpty else { return statement }
    return statement.limit(SwifQLableParts(rawParts: request.countParts))
}

private func _fromAddingOffset(_ request: OffsetClause, to statement: SwifQLable) -> SwifQLable {
    guard !request.countParts.isEmpty else { return statement }
    return statement.offset(SwifQLableParts(rawParts: request.countParts))
}


extension FromBuilder.Partial: FromBuilder.SourceListBranch where Attachment.Role == FromBuilder.SourceList {
    public func finalizeSourceListBranch() -> [[SwifQLPart]] { finalizedFragments() }
}

extension FromBuilder.Partial: FromBuilder.JoinContinuationBranch where Attachment.Role == FromBuilder.JoinContinuationOnly {
    public func finalizeJoinContinuationBranch() -> [[SwifQLPart]] { finalizedFragments() }
}
