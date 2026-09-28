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

    /// Guaranteed FROM clause retained as the current outer owner until another
    /// independent item or a finalized control-flow group closes it.
    public struct GuaranteedFromOwner: FinalizableItem {
        let result: FromBuilder.GuaranteedResult

        public func finalize() -> SwifQLable { result }
    }

    /// Sibling JOIN continuation owned by one guaranteed FROM clause.
    public struct GuaranteedFromJoinCurrent<State: JoinBuilder.JoinState>: FinalizableItem {
        let result: FromBuilder.GuaranteedResult
        let join: State

        public func finalize() -> SwifQLable {
            SQLBuilder.appending(join.finalize().parts, to: result)
        }
    }

    /// A SELECT statement remains open until a typed clause or new statement
    /// closes its current owner.
    public struct SelectOpen: FinalizableItem, WhereAttachable, GroupByAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        init(_ result: SelectBuilder.Result) {
            self.statement = result
        }

        public func finalize() -> SwifQLable { statement }
    }

    /// Maybe-empty FROM owner attached to one open SELECT.
    public struct MaybeFromOwner: FinalizableItem {
        let result: FromBuilder.Result

        public func finalize() -> SwifQLable { result }
    }

    /// FROM result that does not retain a sibling JOIN continuation proof.
    public struct SelectFromOpen: FinalizableItem, WhereAttachable, HavingAttachable, QualifyAttachable, GroupByAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// Guaranteed FROM owner retained with its SELECT for JOIN continuation.
    public struct SelectFromGuaranteedOpen: FinalizableItem, WhereAttachable, HavingAttachable, QualifyAttachable, GroupByAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let selectStatement: SwifQLable
        let from: FromBuilder.GuaranteedResult

        var statement: SwifQLable {
            _SwifQLStructuralComposition.appendStatementContents(from: from, to: selectStatement)
        }

        public func finalize() -> SwifQLable { statement }
    }

    /// WHERE has been consumed; only later legal clause stages remain open.
    public struct SelectWhereOpen: FinalizableItem, HavingAttachable, QualifyAttachable, GroupByAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// GROUP BY has been consumed; later predicate and result-order clauses remain open.
    public struct SelectGroupOpen: FinalizableItem, HavingAttachable, QualifyAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// HAVING has been consumed; only later SQL-order clauses remain open.
    public struct SelectHavingOpen: FinalizableItem, QualifyAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// QUALIFY has been consumed; ordering and row-count clauses may follow.
    public struct SelectQualifyOpen: FinalizableItem, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// ORDER BY has been consumed; LIMIT and OFFSET may follow.
    public struct SelectOrderOpen: FinalizableItem, LimitAttachable, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// LIMIT has been consumed; OFFSET may follow.
    public struct SelectLimitOpen: FinalizableItem, OffsetAttachable {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// OFFSET is the final clause in this wave.
    public struct SelectOffsetOpen: FinalizableItem {
        let statement: SwifQLable

        public func finalize() -> SwifQLable { statement }
    }

    /// JOIN current retained inside an open SELECT/FROM owner.
    public struct SelectFromJoinCurrent<State: JoinBuilder.JoinState>: FinalizableItem, WhereAttachable, HavingAttachable, QualifyAttachable, GroupByAttachable, OrderByAttachable, LimitAttachable, OffsetAttachable {
        let selectStatement: SwifQLable
        let from: FromBuilder.GuaranteedResult
        let join: State

        var statement: SwifQLable {
            let joinedFrom = SQLBuilder.appending(join.finalize().parts, to: from)
            return _SwifQLStructuralComposition.appendStatementContents(from: joinedFrom, to: selectStatement)
        }

        public func finalize() -> SwifQLable { statement }
    }

    protocol WhereAttachable: FinalizableItem {
        var statement: SwifQLable { get }
    }

    protocol HavingAttachable: FinalizableItem {
        var statement: SwifQLable { get }
    }

    protocol QualifyAttachable: FinalizableItem {
        var statement: SwifQLable { get }
    }

    public protocol GroupByAttachable: FinalizableItem {}

    public protocol OrderByAttachable: FinalizableItem {}

    public protocol LimitAttachable: FinalizableItem {}

    public protocol OffsetAttachable: FinalizableItem {}

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

    /// Keeps the statically guaranteed FROM carrier typed at the outer root.
    /// Erased `SwifQLable` values continue through the neutral-fragment path.
    public static func buildExpression(_ expression: FromBuilder.GuaranteedResult) -> GuaranteedFromOwner {
        GuaranteedFromOwner(result: expression)
    }

    public static func buildExpression(_ expression: SelectBuilder.Result) -> SelectOpen {
        SelectOpen(expression)
    }

    public static func buildExpression(_ expression: FromBuilder.Result) -> MaybeFromOwner {
        MaybeFromOwner(result: expression)
    }

    public static func buildExpression(_ request: AliasRequest) -> AliasRequest { request }
    public static func buildExpression(_ request: JoinBuilder.OnRequest) -> JoinBuilder.OnRequest { request }
    public static func buildExpression(_ request: JoinBuilder.UsingRequest) -> JoinBuilder.UsingRequest { request }
    public static func buildExpression(_ request: WhereClause) -> WhereClause { request }
    public static func buildExpression(_ request: HavingClause) -> HavingClause { request }
    public static func buildExpression(_ request: QualifyClause) -> QualifyClause { request }
    public static func buildExpression(_ request: GroupByClause) -> GroupByClause { request }
    public static func buildExpression(_ request: OrderByClause) -> OrderByClause { request }
    public static func buildExpression(_ request: LimitClause) -> LimitClause { request }
    public static func buildExpression(_ request: OffsetClause) -> OffsetClause { request }

    // MARK: - Empty / neutral partial composition

    public static func buildBlock() -> ClosedRoot {
        ClosedRoot(fragments: [])
    }

    public static func buildPartialBlock(first: NeutralItem) -> Partial<NeutralItem> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: GuaranteedFromOwner) -> Partial<GuaranteedFromOwner> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: SelectOpen) -> Partial<SelectOpen> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: MaybeFromOwner) -> Partial<MaybeFromOwner> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock<C: FinalizableItem>(
        accumulated: Partial<C>,
        next: SelectOpen
    ) -> Partial<SelectOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize()], current: next)
    }

    public static func buildPartialBlock(
        accumulated: ClosedRoot,
        next: SelectOpen
    ) -> Partial<SelectOpen> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock<C: FinalizableItem>(
        accumulated: Partial<C>,
        next: MaybeFromOwner
    ) -> Partial<MaybeFromOwner> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize()], current: next)
    }

    public static func buildPartialBlock(
        accumulated: ClosedRoot,
        next: MaybeFromOwner
    ) -> Partial<MaybeFromOwner> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectOpen>,
        next: MaybeFromOwner
    ) -> Partial<SelectFromOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromOpen(
                statement: _SwifQLStructuralComposition.appendStatementContents(
                    from: next.result,
                    to: accumulated.current.statement
                )
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectOpen>,
        next: GuaranteedFromOwner
    ) -> Partial<SelectFromGuaranteedOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromGuaranteedOpen(
                selectStatement: accumulated.current.statement,
                from: next.result
            )
        )
    }

    public static func buildPartialBlock<C: FinalizableItem>(
        accumulated: Partial<C>,
        next: GuaranteedFromOwner
    ) -> Partial<GuaranteedFromOwner> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize()], current: next)
    }

    public static func buildPartialBlock(
        accumulated: ClosedRoot,
        next: GuaranteedFromOwner
    ) -> Partial<GuaranteedFromOwner> {
        Partial(completed: accumulated.fragments, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromOwner>,
        next: JoinBuilder.JoinOpen
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOpen>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(result: accumulated.current.result, join: next)
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromOwner>,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinSourceAliased>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(result: accumulated.current.result, join: next)
        )
    }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<GuaranteedFromJoinCurrent<State>>,
        next: JoinBuilder.JoinOpen
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOpen>> {
        let result = Self.appending(accumulated.current.join.finalize().parts, to: accumulated.current.result)
        return Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(result: result, join: next)
        )
    }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<GuaranteedFromJoinCurrent<State>>,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinSourceAliased>> {
        let result = Self.appending(accumulated.current.join.finalize().parts, to: accumulated.current.result)
        return Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(result: result, join: next)
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOpen>>,
        next: AliasRequest
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinSourceAliased>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(
                result: accumulated.current.result,
                join: accumulated.current.join.addingAlias(next.name)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinUsing>>,
        next: AliasRequest
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinUsingAliased>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(
                result: accumulated.current.result,
                join: accumulated.current.join.addingAlias(next.name)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOpen>>,
        next: JoinBuilder.OnRequest
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOnQualified>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(
                result: accumulated.current.result,
                join: accumulated.current.join.addingOn(next.parts)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinSourceAliased>>,
        next: JoinBuilder.OnRequest
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOnQualified>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(
                result: accumulated.current.result,
                join: accumulated.current.join.addingOn(next.parts)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinOpen>>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinUsing>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(
                result: accumulated.current.result,
                join: accumulated.current.join.addingUsing(next.names)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinSourceAliased>>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<GuaranteedFromJoinCurrent<JoinBuilder.JoinUsing>> {
        Partial(
            completed: accumulated.completed,
            current: GuaranteedFromJoinCurrent(
                result: accumulated.current.result,
                join: accumulated.current.join.addingUsing(next.names)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromGuaranteedOpen>,
        next: JoinBuilder.JoinOpen
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinOpen>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: next
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromGuaranteedOpen>,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinSourceAliased>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: next
            )
        )
    }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<SelectFromJoinCurrent<State>>,
        next: JoinBuilder.JoinOpen
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinOpen>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: Self.appending(accumulated.current.join.finalize().parts, to: accumulated.current.from),
                join: next
            )
        )
    }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<SelectFromJoinCurrent<State>>,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinSourceAliased>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: Self.appending(accumulated.current.join.finalize().parts, to: accumulated.current.from),
                join: next
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromJoinCurrent<JoinBuilder.JoinOpen>>,
        next: AliasRequest
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinSourceAliased>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: accumulated.current.join.addingAlias(next.name)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromJoinCurrent<JoinBuilder.JoinUsing>>,
        next: AliasRequest
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinUsingAliased>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: accumulated.current.join.addingAlias(next.name)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromJoinCurrent<JoinBuilder.JoinOpen>>,
        next: JoinBuilder.OnRequest
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinOnQualified>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: accumulated.current.join.addingOn(next.parts)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromJoinCurrent<JoinBuilder.JoinSourceAliased>>,
        next: JoinBuilder.OnRequest
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinOnQualified>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: accumulated.current.join.addingOn(next.parts)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromJoinCurrent<JoinBuilder.JoinOpen>>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinUsing>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: accumulated.current.join.addingUsing(next.names)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromJoinCurrent<JoinBuilder.JoinSourceAliased>>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<SelectFromJoinCurrent<JoinBuilder.JoinUsing>> {
        Partial(
            completed: accumulated.completed,
            current: SelectFromJoinCurrent(
                selectStatement: accumulated.current.selectStatement,
                from: accumulated.current.from,
                join: accumulated.current.join.addingUsing(next.names)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: Partial<SelectOpen>,
        next: WhereClause
    ) -> Partial<SelectWhereOpen> { attachingWhere(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromOpen>,
        next: WhereClause
    ) -> Partial<SelectWhereOpen> { attachingWhere(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromGuaranteedOpen>,
        next: WhereClause
    ) -> Partial<SelectWhereOpen> { attachingWhere(accumulated, next) }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<SelectFromJoinCurrent<State>>,
        next: WhereClause
    ) -> Partial<SelectWhereOpen> { attachingWhere(accumulated, next) }

    public static func buildPartialBlock<Current: GroupByAttachable>(
        accumulated: Partial<Current>,
        next: GroupByClause
    ) -> Partial<SelectGroupOpen> { attachingGroupBy(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromOpen>,
        next: HavingClause
    ) -> Partial<SelectHavingOpen> { attachingHaving(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromGuaranteedOpen>,
        next: HavingClause
    ) -> Partial<SelectHavingOpen> { attachingHaving(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectWhereOpen>,
        next: HavingClause
    ) -> Partial<SelectHavingOpen> { attachingHaving(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectGroupOpen>,
        next: HavingClause
    ) -> Partial<SelectHavingOpen> { attachingHaving(accumulated, next) }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<SelectFromJoinCurrent<State>>,
        next: HavingClause
    ) -> Partial<SelectHavingOpen> { attachingHaving(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromOpen>,
        next: QualifyClause
    ) -> Partial<SelectQualifyOpen> { attachingQualify(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectFromGuaranteedOpen>,
        next: QualifyClause
    ) -> Partial<SelectQualifyOpen> { attachingQualify(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectWhereOpen>,
        next: QualifyClause
    ) -> Partial<SelectQualifyOpen> { attachingQualify(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectHavingOpen>,
        next: QualifyClause
    ) -> Partial<SelectQualifyOpen> { attachingQualify(accumulated, next) }

    public static func buildPartialBlock(
        accumulated: Partial<SelectGroupOpen>,
        next: QualifyClause
    ) -> Partial<SelectQualifyOpen> { attachingQualify(accumulated, next) }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<SelectFromJoinCurrent<State>>,
        next: QualifyClause
    ) -> Partial<SelectQualifyOpen> { attachingQualify(accumulated, next) }

    public static func buildPartialBlock<Current: OrderByAttachable>(
        accumulated: Partial<Current>,
        next: OrderByClause
    ) -> Partial<SelectOrderOpen> { attachingOrderBy(accumulated, next) }

    public static func buildPartialBlock<Current: LimitAttachable>(
        accumulated: Partial<Current>,
        next: LimitClause
    ) -> Partial<SelectLimitOpen> { attachingLimit(accumulated, next) }

    public static func buildPartialBlock<Current: OffsetAttachable>(
        accumulated: Partial<Current>,
        next: OffsetClause
    ) -> Partial<SelectOffsetOpen> { attachingOffset(accumulated, next) }

    public static func buildPartialBlock<State: JoinBuilder.JoinState>(
        accumulated: Partial<GuaranteedFromJoinCurrent<State>>,
        next: NeutralItem
    ) -> Partial<NeutralItem> {
        Partial(completed: accumulated.completed + [accumulated.current.finalize()], current: next)
    }

    private static func appending(
        _ joinParts: [SwifQLPart],
        to result: FromBuilder.GuaranteedResult
    ) -> FromBuilder.GuaranteedResult {
        var items = result.itemFragments
        items.append(joinParts)
        return FromBuilder.GuaranteedResult(children: FromBuilder.assemble(items), itemFragments: items)
    }

    private static func addingWhere(_ request: WhereClause, to statement: SwifQLable) -> SwifQLable {
        guard !request.predicateParts.isEmpty else { return statement }
        return statement.where(SwifQLableParts(rawParts: request.predicateParts))
    }

    private static func addingHaving(_ request: HavingClause, to statement: SwifQLable) -> SwifQLable {
        guard !request.predicateParts.isEmpty else { return statement }
        return statement.having(SwifQLableParts(rawParts: request.predicateParts))
    }

    private static func addingQualify(_ request: QualifyClause, to statement: SwifQLable) -> SwifQLable {
        guard !request.predicateParts.isEmpty else { return statement }
        return statement.qualify(SwifQLableParts(rawParts: request.predicateParts))
    }

    private static func addingGroupBy(_ request: GroupByClause, to statement: SwifQLable) -> SwifQLable {
        let expressions = request.expressionParts
            .filter { !$0.isEmpty }
            .map { SwifQLableParts(rawParts: $0) as SwifQLable }
        guard !expressions.isEmpty else { return statement }
        return statement.groupBy(expressions)
    }

    private static func addingOrderBy(_ request: OrderByClause, to statement: SwifQLable) -> SwifQLable {
        guard !request.items.isEmpty else { return statement }
        return statement.orderBy(request.items)
    }

    private static func addingLimit(_ request: LimitClause, to statement: SwifQLable) -> SwifQLable {
        guard !request.countParts.isEmpty else { return statement }
        return statement.limit(SwifQLableParts(rawParts: request.countParts))
    }

    private static func addingOffset(_ request: OffsetClause, to statement: SwifQLable) -> SwifQLable {
        guard !request.countParts.isEmpty else { return statement }
        return statement.offset(SwifQLableParts(rawParts: request.countParts))
    }

    private static func attachingWhere<Current: WhereAttachable>(
        _ accumulated: Partial<Current>,
        _ request: WhereClause
    ) -> Partial<SelectWhereOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectWhereOpen(statement: addingWhere(request, to: accumulated.current.statement))
        )
    }

    private static func attachingHaving<Current: HavingAttachable>(
        _ accumulated: Partial<Current>,
        _ request: HavingClause
    ) -> Partial<SelectHavingOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectHavingOpen(statement: addingHaving(request, to: accumulated.current.statement))
        )
    }

    private static func attachingQualify<Current: QualifyAttachable>(
        _ accumulated: Partial<Current>,
        _ request: QualifyClause
    ) -> Partial<SelectQualifyOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectQualifyOpen(statement: addingQualify(request, to: accumulated.current.statement))
        )
    }

    private static func attachingGroupBy<Current: GroupByAttachable>(
        _ accumulated: Partial<Current>,
        _ request: GroupByClause
    ) -> Partial<SelectGroupOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectGroupOpen(statement: addingGroupBy(request, to: accumulated.current.finalize()))
        )
    }

    private static func attachingOrderBy<Current: OrderByAttachable>(
        _ accumulated: Partial<Current>,
        _ request: OrderByClause
    ) -> Partial<SelectOrderOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectOrderOpen(statement: addingOrderBy(request, to: accumulated.current.finalize()))
        )
    }

    private static func attachingLimit<Current: LimitAttachable>(
        _ accumulated: Partial<Current>,
        _ request: LimitClause
    ) -> Partial<SelectLimitOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectLimitOpen(statement: addingLimit(request, to: accumulated.current.finalize()))
        )
    }

    private static func attachingOffset<Current: OffsetAttachable>(
        _ accumulated: Partial<Current>,
        _ request: OffsetClause
    ) -> Partial<SelectOffsetOpen> {
        Partial(
            completed: accumulated.completed,
            current: SelectOffsetOpen(statement: addingOffset(request, to: accumulated.current.finalize()))
        )
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
