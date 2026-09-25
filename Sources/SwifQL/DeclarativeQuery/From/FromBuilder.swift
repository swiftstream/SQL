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
    public struct NestedSelectOpen: AliasableCurrent {
        let statementParts: [SwifQLPart]

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
    public struct NestedFromOpen: AliasableCurrent {
        let statementParts: [SwifQLPart]

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

    // MARK: - Expressions

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


extension FromBuilder.Partial: FromBuilder.SourceListBranch where Attachment.Role == FromBuilder.SourceList {
    public func finalizeSourceListBranch() -> [[SwifQLPart]] { finalizedFragments() }
}

extension FromBuilder.Partial: FromBuilder.JoinContinuationBranch where Attachment.Role == FromBuilder.JoinContinuationOnly {
    public func finalizeJoinContinuationBranch() -> [[SwifQLPart]] { finalizedFragments() }
}
