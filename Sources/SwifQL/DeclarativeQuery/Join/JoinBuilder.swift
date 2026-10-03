import Foundation

/// Typed current states and local transitions for declarative JOIN items.
public enum JoinBuilder {
    public protocol JoinState: FromBuilder.CurrentState {}

    public struct JoinOpen: JoinState, FromBuilder.AliasableCurrent, SwifQLable {
        public typealias Aliased = JoinSourceAliased

        let joinParts: [SwifQLPart]

        init(modeParts: [SwifQLPartOperator], sourceParts: [SwifQLPart]) {
            var parts: [SwifQLPart] = []
            parts.append(contentsOf: modeParts)
            parts.append(o: .space)
            parts.append(contentsOf: sourceParts)
            self.joinParts = parts
        }

        init(joinParts: [SwifQLPart]) {
            self.joinParts = joinParts
        }

        public var parts: [SwifQLPart] { joinParts }
        public func finalize() -> SwifQLable { SwifQLableParts(rawParts: joinParts) }

        public func addingAlias(_ name: String) -> JoinSourceAliased {
            var parts = joinParts
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(SwifQLPartAlias(name))
            return JoinSourceAliased(joinParts: parts)
        }

        func addingOn(_ predicateParts: [SwifQLPart]) -> JoinOnQualified {
            var parts = joinParts
            if !predicateParts.isEmpty {
                parts.append(o: .space, .custom("ON"), .space)
                parts.append(contentsOf: predicateParts)
            }
            return JoinOnQualified(joinParts: parts)
        }

        func addingUsing(_ names: [String]) -> JoinUsing {
            var parts = joinParts
            parts.append(o: .space, .custom("USING"), .space, .openBracket)
            for (index, name) in names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartColumn(name))
            }
            parts.append(o: .closeBracket)
            return JoinUsing(joinParts: parts)
        }
    }

    public struct JoinSourceAliased: JoinState, SwifQLable {
        let joinParts: [SwifQLPart]

        init(joinParts: [SwifQLPart]) {
            self.joinParts = joinParts
        }

        public var parts: [SwifQLPart] { joinParts }
        public func finalize() -> SwifQLable { SwifQLableParts(rawParts: joinParts) }

        func addingOn(_ predicateParts: [SwifQLPart]) -> JoinOnQualified {
            var parts = joinParts
            if !predicateParts.isEmpty {
                parts.append(o: .space, .custom("ON"), .space)
                parts.append(contentsOf: predicateParts)
            }
            return JoinOnQualified(joinParts: parts)
        }

        func addingUsing(_ names: [String]) -> JoinUsing {
            var parts = joinParts
            parts.append(o: .space, .custom("USING"), .space, .openBracket)
            for (index, name) in names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartColumn(name))
            }
            parts.append(o: .closeBracket)
            return JoinUsing(joinParts: parts)
        }
    }

    public struct JoinOnQualified: JoinState, SwifQLable {
        let joinParts: [SwifQLPart]

        init(joinParts: [SwifQLPart]) {
            self.joinParts = joinParts
        }

        public var parts: [SwifQLPart] { joinParts }
        public func finalize() -> SwifQLable { SwifQLableParts(rawParts: joinParts) }
    }

    public struct JoinUsing: JoinState, FromBuilder.AliasableCurrent, SwifQLable {
        public typealias Aliased = JoinUsingAliased
        let joinParts: [SwifQLPart]

        init(joinParts: [SwifQLPart]) {
            self.joinParts = joinParts
        }

        public var parts: [SwifQLPart] { joinParts }
        public func finalize() -> SwifQLable { SwifQLableParts(rawParts: joinParts) }

        public func addingAlias(_ name: String) -> JoinUsingAliased {
            var parts = joinParts
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(SwifQLPartAlias(name))
            return JoinUsingAliased(joinParts: parts)
        }
    }

    public struct JoinUsingAliased: JoinState, SwifQLable {
        let joinParts: [SwifQLPart]

        init(joinParts: [SwifQLPart]) {
            self.joinParts = joinParts
        }

        public var parts: [SwifQLPart] { joinParts }
        public func finalize() -> SwifQLable { SwifQLableParts(rawParts: joinParts) }
    }

    public struct OnRequest: SwifQLable {
        let predicateParts: [SwifQLPart]

        init(parts: [SwifQLPart]) { self.predicateParts = parts }

        public var parts: [SwifQLPart] {
            guard !predicateParts.isEmpty else { return [] }
            var parts: [SwifQLPart] = []
            parts.append(o: .custom("ON"), .space)
            parts.append(contentsOf: predicateParts)
            return parts
        }
    }

    public struct UsingRequest: SwifQLable {
        let names: [String]

        init(names: [String]) { self.names = names }

        public var parts: [SwifQLPart] {
            var parts: [SwifQLPart] = []
            parts.append(o: .custom("USING"), .space, .openBracket)
            for (index, name) in names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartColumn(name))
            }
            parts.append(o: .closeBracket)
            return parts
        }
    }
}

public extension JoinBuilder.JoinState {
    func asFromItem() -> FromBuilder.FromItem {
        FromBuilder.FromItem(kind: .joinContinuation, parts: finalize().parts)
    }
}

extension FromBuilder {
    public static func buildExpression(_ expression: JoinBuilder.JoinSourceAliased) -> JoinBuilder.JoinSourceAliased {
        expression
    }

    public static func buildExpression(_ expression: JoinBuilder.JoinOpen) -> JoinBuilder.JoinOpen {
        expression
    }

    public static func buildPartialBlock(first: JoinBuilder.JoinOpen) -> Partial<JoinBuilder.JoinOpen> {
        Partial(completed: [], current: first)
    }

    public static func buildPartialBlock(first: JoinBuilder.JoinSourceAliased) -> Partial<JoinBuilder.JoinSourceAliased> {
        Partial(completed: [], current: first)
    }

    /// A JOIN is a distinct ordered element; the local reducer supplies its spacing.
    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next: JoinBuilder.JoinOpen
    ) -> Partial<JoinBuilder.JoinOpen> {
        Partial(completed: accumulated.completed + [accumulated.current.asFromItem()], current: next)
    }

    public static func buildPartialBlock<Current: CurrentState>(
        accumulated: Partial<Current>,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<JoinBuilder.JoinSourceAliased> {
        Partial(completed: accumulated.completed + [accumulated.current.asFromItem()], current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next: JoinBuilder.JoinOpen
    ) -> Partial<JoinBuilder.JoinOpen> {
        Partial(completed: accumulated.items, current: next)
    }

    public static func buildPartialBlock(
        accumulated: Closed,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<JoinBuilder.JoinSourceAliased> {
        Partial(completed: accumulated.items, current: next)
    }

    public static func buildExpression(_ request: JoinBuilder.OnRequest) -> JoinBuilder.OnRequest {
        request
    }

    public static func buildExpression(_ request: JoinBuilder.UsingRequest) -> JoinBuilder.UsingRequest {
        request
    }

    public static func buildPartialBlock(
        accumulated: Partial<JoinBuilder.JoinOpen>,
        next: JoinBuilder.OnRequest
    ) -> Partial<JoinBuilder.JoinOnQualified> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingOn(next.predicateParts))
    }

    public static func buildPartialBlock(
        accumulated: Partial<JoinBuilder.JoinSourceAliased>,
        next: JoinBuilder.OnRequest
    ) -> Partial<JoinBuilder.JoinOnQualified> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingOn(next.predicateParts))
    }

    public static func buildPartialBlock(
        accumulated: Partial<JoinBuilder.JoinOpen>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<JoinBuilder.JoinUsing> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingUsing(next.names))
    }

    public static func buildPartialBlock(
        accumulated: Partial<JoinBuilder.JoinSourceAliased>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<JoinBuilder.JoinUsing> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingUsing(next.names))
    }

    public static func buildPartialBlock(
        accumulated: Partial<JoinBuilder.JoinUsing>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<JoinBuilder.JoinUsingAliased> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingAlias(next.name))
    }
}
