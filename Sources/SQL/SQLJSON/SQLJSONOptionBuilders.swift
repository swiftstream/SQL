//
//  SQLJSONOptionBuilders.swift
//  SQL
//

import Foundation

// MARK: - Typed option state

/// One SQL/JSON option clause lowered into ordered parts: `PASSING` entries stay
/// separate so a single keyword can coalesce them, and later clause fragments
/// keep the grammar order in which the typed state admitted them.
public struct SQLJSONOptions {
    let passingEntries: [[SQLPart]]
    let tailParts: [SQLPart]

    init(passingEntries: [[SQLPart]], tailParts: [SQLPart]) {
        self.passingEntries = passingEntries
        self.tailParts = tailParts
    }

    static var empty: SQLJSONOptions {
        .init(passingEntries: [], tailParts: [])
    }
}

/// Intermediate builder state for one owner. The `Phase` marker is the only
/// difference between states, and it is what makes a duplicate or out-of-order
/// role fail overload resolution instead of being detected after rendering.
public struct SQLJSONOptionsState<Phase> {
    let passingEntries: [[SQLPart]]
    let tailParts: [SQLPart]

    init(passingEntries: [[SQLPart]], tailParts: [SQLPart]) {
        self.passingEntries = passingEntries
        self.tailParts = tailParts
    }

    static var empty: Self {
        .init(passingEntries: [], tailParts: [])
    }

    static func started(_ passing: JSONPassingNode) -> Self {
        .init(passingEntries: [passing.entryParts], tailParts: [])
    }

    static func started(_ nodeParts: [SQLPart]) -> Self {
        .init(passingEntries: [], tailParts: nodeParts)
    }

    func appending(_ passing: JSONPassingNode) -> Self {
        .init(passingEntries: passingEntries + [passing.entryParts], tailParts: tailParts)
    }

    func merged(with other: Self) -> Self {
        .init(
            passingEntries: passingEntries + other.passingEntries,
            tailParts: tailParts + other.tailParts
        )
    }

    func advancing<NextPhase>(_ nodeParts: [SQLPart]) -> SQLJSONOptionsState<NextPhase> {
        .init(passingEntries: passingEntries, tailParts: tailParts + nodeParts)
    }

    func advancing<NextPhase, Other>(
        _ other: SQLJSONOptionsState<Other>
    ) -> SQLJSONOptionsState<NextPhase> {
        .init(
            passingEntries: passingEntries + other.passingEntries,
            tailParts: tailParts + other.tailParts
        )
    }

    var lowered: SQLJSONOptions {
        .init(passingEntries: passingEntries, tailParts: tailParts)
    }
}

public struct SQLJSONExistsPassingPhase {}
public struct SQLJSONExistsOnErrorPhase {}

public struct SQLJSONValuePassingPhase {}
public struct SQLJSONValueReturningPhase {}
public struct SQLJSONValueOnEmptyPhase {}
public struct SQLJSONValueOnErrorPhase {}

public struct SQLJSONQueryPassingPhase {}
public struct SQLJSONQueryReturningPhase {}
public struct SQLJSONQueryWrapperPhase {}
public struct SQLJSONQueryQuotesPhase {}
public struct SQLJSONQueryOnEmptyPhase {}
public struct SQLJSONQueryOnErrorPhase {}

// MARK: - JSON_EXISTS grammar

/// `Passing* -> OnError?`. `RETURNING`, any `ON EMPTY`, wrapper, and quote
/// behavior do not exist inside this owner, so no transition admits them.
@resultBuilder
public enum JSONExistsBuilder {
    public typealias Open = SQLJSONOptionsState<SQLJSONExistsPassingPhase>
    public typealias OnErrorDone = SQLJSONOptionsState<SQLJSONExistsOnErrorPhase>

    public static func buildBlock() -> Open {
        .empty
    }

    public static func buildPartialBlock(first passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildPartialBlock(first state: Open) -> Open {
        state
    }

    public static func buildPartialBlock(first error: JSONBooleanOnErrorNode) -> OnErrorDone {
        .started(error.fragmentParts)
    }

    public static func buildPartialBlock(first error: JSONOnErrorBehaviorNode) -> OnErrorDone {
        .started(error.fragmentParts)
    }

    public static func buildPartialBlock(first state: OnErrorDone) -> OnErrorDone {
        state
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next passing: JSONPassingNode
    ) -> Open {
        accumulated.appending(passing)
    }

    public static func buildPartialBlock(accumulated: Open, next state: Open) -> Open {
        accumulated.merged(with: state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONBooleanOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildOptional(_ state: Open?) -> Open {
        state ?? .empty
    }

    public static func buildEither(first passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildEither(second passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildEither<Phase>(
        first state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptionsState<Phase> {
        state
    }

    public static func buildEither<Phase>(
        second state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptionsState<Phase> {
        state
    }

    public static func buildArray(_ components: [Open]) -> Open {
        components.reduce(into: .empty) { partialResult, state in
            partialResult = partialResult.merged(with: state)
        }
    }

    public static func buildFinalResult<Phase>(
        _ state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptions {
        state.lowered
    }
}

// MARK: - JSON_VALUE grammar

/// `Passing* -> Returning? -> OnEmpty? -> OnError?`. Formatted `RETURNING`,
/// wrapper, quote, boolean `ON ERROR`, and empty-result behavior are not part
/// of this owner's grammar, so no transition admits them.
@resultBuilder
public enum JSONValueBuilder {
    public typealias Open = SQLJSONOptionsState<SQLJSONValuePassingPhase>
    public typealias ReturningDone = SQLJSONOptionsState<SQLJSONValueReturningPhase>
    public typealias OnEmptyDone = SQLJSONOptionsState<SQLJSONValueOnEmptyPhase>
    public typealias OnErrorDone = SQLJSONOptionsState<SQLJSONValueOnErrorPhase>

    public static func buildBlock() -> Open {
        .empty
    }

    public static func buildPartialBlock(first passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildPartialBlock(first state: Open) -> Open {
        state
    }

    public static func buildPartialBlock(first returning: JSONReturningNode) -> ReturningDone {
        .started(returning.fragmentParts)
    }

    public static func buildPartialBlock(first state: ReturningDone) -> ReturningDone {
        state
    }

    public static func buildPartialBlock(
        first empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        .started(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        first empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        .started(empty.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(first state: OnEmptyDone) -> OnEmptyDone {
        state
    }

    public static func buildPartialBlock(
        first error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        .started(error.fragmentParts)
    }

    public static func buildPartialBlock(
        first error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        .started(error.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(first state: OnErrorDone) -> OnErrorDone {
        state
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next passing: JSONPassingNode
    ) -> Open {
        accumulated.appending(passing)
    }

    public static func buildPartialBlock(accumulated: Open, next state: Open) -> Open {
        accumulated.merged(with: state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next returning: JSONReturningNode
    ) -> ReturningDone {
        accumulated.advancing(returning.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: ReturningDone
    ) -> ReturningDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: OnEmptyDone
    ) -> OnEmptyDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next state: OnEmptyDone
    ) -> OnEmptyDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonValue))
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildOptional(_ state: Open?) -> Open {
        state ?? .empty
    }

    public static func buildEither(first passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildEither(second passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildEither<Phase>(
        first state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptionsState<Phase> {
        state
    }

    public static func buildEither<Phase>(
        second state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptionsState<Phase> {
        state
    }

    public static func buildArray(_ components: [Open]) -> Open {
        components.reduce(into: .empty) { partialResult, state in
            partialResult = partialResult.merged(with: state)
        }
    }

    public static func buildFinalResult<Phase>(
        _ state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptions {
        state.lowered
    }
}

// MARK: - JSON_QUERY grammar

/// `Passing* -> Returning? -> Wrapper? -> Quotes? -> OnEmpty? -> OnError?`.
/// Boolean `ON ERROR` belongs to `JSON_EXISTS` only, so no transition admits it.
@resultBuilder
public enum JSONQueryBuilder {
    public typealias Open = SQLJSONOptionsState<SQLJSONQueryPassingPhase>
    public typealias ReturningDone = SQLJSONOptionsState<SQLJSONQueryReturningPhase>
    public typealias WrapperDone = SQLJSONOptionsState<SQLJSONQueryWrapperPhase>
    public typealias QuotesDone = SQLJSONOptionsState<SQLJSONQueryQuotesPhase>
    public typealias OnEmptyDone = SQLJSONOptionsState<SQLJSONQueryOnEmptyPhase>
    public typealias OnErrorDone = SQLJSONOptionsState<SQLJSONQueryOnErrorPhase>

    public static func buildBlock() -> Open {
        .empty
    }

    public static func buildPartialBlock(first passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildPartialBlock(first state: Open) -> Open {
        state
    }

    public static func buildPartialBlock(first returning: JSONReturningNode) -> ReturningDone {
        .started(returning.fragmentParts)
    }

    public static func buildPartialBlock(
        first returning: JSONFormattedReturningNode
    ) -> ReturningDone {
        .started(returning.fragmentParts)
    }

    public static func buildPartialBlock(first state: ReturningDone) -> ReturningDone {
        state
    }

    public static func buildPartialBlock(
        first wrapper: JSONWrapperBehaviorNode
    ) -> WrapperDone {
        .started(wrapper.fragmentParts)
    }

    public static func buildPartialBlock(first state: WrapperDone) -> WrapperDone {
        state
    }

    public static func buildPartialBlock(first quotes: JSONQuotesBehaviorNode) -> QuotesDone {
        .started(quotes.fragmentParts)
    }

    public static func buildPartialBlock(first state: QuotesDone) -> QuotesDone {
        state
    }

    public static func buildPartialBlock(
        first empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        .started(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        first empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        .started(empty.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        first empty: JSONEmptyResultOnEmptyNode
    ) -> OnEmptyDone {
        .started(empty.fragmentParts)
    }

    public static func buildPartialBlock(first state: OnEmptyDone) -> OnEmptyDone {
        state
    }

    public static func buildPartialBlock(
        first error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        .started(error.fragmentParts)
    }

    public static func buildPartialBlock(
        first error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        .started(error.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        first error: JSONEmptyResultOnErrorNode
    ) -> OnErrorDone {
        .started(error.fragmentParts)
    }

    public static func buildPartialBlock(first state: OnErrorDone) -> OnErrorDone {
        state
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next passing: JSONPassingNode
    ) -> Open {
        accumulated.appending(passing)
    }

    public static func buildPartialBlock(accumulated: Open, next state: Open) -> Open {
        accumulated.merged(with: state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next returning: JSONReturningNode
    ) -> ReturningDone {
        accumulated.advancing(returning.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next returning: JSONFormattedReturningNode
    ) -> ReturningDone {
        accumulated.advancing(returning.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: ReturningDone
    ) -> ReturningDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next wrapper: JSONWrapperBehaviorNode
    ) -> WrapperDone {
        accumulated.advancing(wrapper.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: WrapperDone
    ) -> WrapperDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next quotes: JSONQuotesBehaviorNode
    ) -> QuotesDone {
        accumulated.advancing(quotes.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: QuotesDone
    ) -> QuotesDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next empty: JSONEmptyResultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: OnEmptyDone
    ) -> OnEmptyDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next error: JSONEmptyResultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: Open,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next wrapper: JSONWrapperBehaviorNode
    ) -> WrapperDone {
        accumulated.advancing(wrapper.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next state: WrapperDone
    ) -> WrapperDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next quotes: JSONQuotesBehaviorNode
    ) -> QuotesDone {
        accumulated.advancing(quotes.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next state: QuotesDone
    ) -> QuotesDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next empty: JSONEmptyResultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next state: OnEmptyDone
    ) -> OnEmptyDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next error: JSONEmptyResultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: ReturningDone,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next quotes: JSONQuotesBehaviorNode
    ) -> QuotesDone {
        accumulated.advancing(quotes.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next state: QuotesDone
    ) -> QuotesDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next empty: JSONEmptyResultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next state: OnEmptyDone
    ) -> OnEmptyDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next error: JSONEmptyResultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: WrapperDone,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next empty: JSONOnEmptyBehaviorNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next empty: JSONDefaultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next empty: JSONEmptyResultOnEmptyNode
    ) -> OnEmptyDone {
        accumulated.advancing(empty.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next state: OnEmptyDone
    ) -> OnEmptyDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next error: JSONEmptyResultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: QuotesDone,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next error: JSONOnErrorBehaviorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next error: JSONDefaultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts(owner: .jsonQuery))
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next error: JSONEmptyResultOnErrorNode
    ) -> OnErrorDone {
        accumulated.advancing(error.fragmentParts)
    }

    public static func buildPartialBlock(
        accumulated: OnEmptyDone,
        next state: OnErrorDone
    ) -> OnErrorDone {
        accumulated.advancing(state)
    }

    public static func buildOptional(_ state: Open?) -> Open {
        state ?? .empty
    }

    public static func buildEither(first passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildEither(second passing: JSONPassingNode) -> Open {
        .started(passing)
    }

    public static func buildEither<Phase>(
        first state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptionsState<Phase> {
        state
    }

    public static func buildEither<Phase>(
        second state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptionsState<Phase> {
        state
    }

    public static func buildArray(_ components: [Open]) -> Open {
        components.reduce(into: .empty) { partialResult, state in
            partialResult = partialResult.merged(with: state)
        }
    }

    public static func buildFinalResult<Phase>(
        _ state: SQLJSONOptionsState<Phase>
    ) -> SQLJSONOptions {
        state.lowered
    }
}
