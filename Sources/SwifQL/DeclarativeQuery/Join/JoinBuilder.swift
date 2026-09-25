import Foundation

/// Typed current states and state transitions for declarative JOIN items.
public enum JoinBuilder {
    public protocol JoinState: FromBuilder.CurrentState {}

    public struct JoinOpen: JoinState, FromBuilder.AliasableCurrent {
        public typealias Aliased = JoinSourceAliased

        let baseSourceParts: [SwifQLPart]?
        let joinParts: [SwifQLPart]

        init(modeParts: [SwifQLPartOperator], sourceParts: [SwifQLPart]) {
            var parts: [SwifQLPart] = []
            parts.append(contentsOf: modeParts)
            parts.append(o: .space)
            parts.append(contentsOf: sourceParts)
            self.baseSourceParts = nil
            self.joinParts = parts
        }

        init(baseSourceParts: [SwifQLPart]?, joinParts: [SwifQLPart]) {
            self.baseSourceParts = baseSourceParts
            self.joinParts = joinParts
        }

        public func finalize() -> SwifQLable {
            var parts: [SwifQLPart] = []
            if let baseSourceParts {
                parts.append(contentsOf: baseSourceParts)
                parts.append(o: .space)
            } else {
                parts.append(FromBuilder.JoinContinuationPart())
            }
            parts.append(contentsOf: joinParts)
            return SwifQLableParts(rawParts: parts)
        }

        public func addingAlias(_ name: String) -> JoinSourceAliased {
            var parts = joinParts
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(SwifQLPartAlias(name))
            return JoinSourceAliased(baseSourceParts: baseSourceParts, joinParts: parts)
        }

        func addingBaseSource(_ parts: [SwifQLPart]) -> JoinOpen {
            JoinOpen(baseSourceParts: parts, joinParts: joinParts)
        }

        func addingOn(_ predicateParts: [SwifQLPart]) -> JoinOnQualified {
            var parts = joinParts
            if !predicateParts.isEmpty {
                parts.append(o: .space, .custom("ON"), .space)
                parts.append(contentsOf: predicateParts)
            }
            return JoinOnQualified(baseSourceParts: baseSourceParts, joinParts: parts)
        }

        func addingUsing(_ names: [String]) -> JoinUsing {
            var parts = joinParts
            parts.append(o: .space, .custom("USING"), .space, .openBracket)
            for (index, name) in names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartColumn(name))
            }
            parts.append(o: .closeBracket)
            return JoinUsing(baseSourceParts: baseSourceParts, joinParts: parts)
        }

    }

    public struct JoinSourceAliased: JoinState {
        let baseSourceParts: [SwifQLPart]?
        let joinParts: [SwifQLPart]

        init(baseSourceParts: [SwifQLPart]?, joinParts: [SwifQLPart]) {
            self.baseSourceParts = baseSourceParts
            self.joinParts = joinParts
        }

        public func finalize() -> SwifQLable { joinedParts() }

        func joinedParts() -> SwifQLable {
            Self.joined(baseSourceParts, joinParts)
        }

        func addingOn(_ predicateParts: [SwifQLPart]) -> JoinOnQualified {
            var parts = joinParts
            if !predicateParts.isEmpty {
                parts.append(o: .space, .custom("ON"), .space)
                parts.append(contentsOf: predicateParts)
            }
            return JoinOnQualified(baseSourceParts: baseSourceParts, joinParts: parts)
        }

        func addingUsing(_ names: [String]) -> JoinUsing {
            var parts = joinParts
            parts.append(o: .space, .custom("USING"), .space, .openBracket)
            for (index, name) in names.enumerated() {
                if index > 0 { parts.append(o: .comma, .space) }
                parts.append(SwifQLPartColumn(name))
            }
            parts.append(o: .closeBracket)
            return JoinUsing(baseSourceParts: baseSourceParts, joinParts: parts)
        }

        func addingBaseSource(_ parts: [SwifQLPart]) -> JoinSourceAliased {
            JoinSourceAliased(baseSourceParts: parts, joinParts: joinParts)
        }

        fileprivate static func joined(
            _ baseSourceParts: [SwifQLPart]?,
            _ joinParts: [SwifQLPart]
        ) -> SwifQLable {
            var parts: [SwifQLPart] = []
            if let baseSourceParts {
                parts.append(contentsOf: baseSourceParts)
                parts.append(o: .space)
            } else {
                parts.append(FromBuilder.JoinContinuationPart())
            }
            parts.append(contentsOf: joinParts)
            return SwifQLableParts(rawParts: parts)
        }
    }

    public struct JoinOnQualified: JoinState {
        let baseSourceParts: [SwifQLPart]?
        let joinParts: [SwifQLPart]

        init(baseSourceParts: [SwifQLPart]?, joinParts: [SwifQLPart]) {
            self.baseSourceParts = baseSourceParts
            self.joinParts = joinParts
        }

        public func finalize() -> SwifQLable {
            JoinSourceAliased.joined(baseSourceParts, joinParts)
        }
    }

    public struct JoinUsing: JoinState, FromBuilder.AliasableCurrent {
        public typealias Aliased = JoinUsingAliased

        let baseSourceParts: [SwifQLPart]?
        let joinParts: [SwifQLPart]

        init(baseSourceParts: [SwifQLPart]?, joinParts: [SwifQLPart]) {
            self.baseSourceParts = baseSourceParts
            self.joinParts = joinParts
        }

        public func finalize() -> SwifQLable {
            JoinSourceAliased.joined(baseSourceParts, joinParts)
        }

        public func addingAlias(_ name: String) -> JoinUsingAliased {
            var parts = joinParts
            parts.append(o: .space, .custom("AS"), .space)
            parts.append(SwifQLPartAlias(name))
            return JoinUsingAliased(baseSourceParts: baseSourceParts, joinParts: parts)
        }
    }

    public struct JoinUsingAliased: JoinState {
        let baseSourceParts: [SwifQLPart]?
        let joinParts: [SwifQLPart]

        init(baseSourceParts: [SwifQLPart]?, joinParts: [SwifQLPart]) {
            self.baseSourceParts = baseSourceParts
            self.joinParts = joinParts
        }

        public func finalize() -> SwifQLable {
            JoinSourceAliased.joined(baseSourceParts, joinParts)
        }
    }

    public struct OnRequest {
        let parts: [SwifQLPart]

        init(parts: [SwifQLPart]) { self.parts = parts }
    }

    public struct UsingRequest {
        let names: [String]

        init(names: [String]) { self.names = names }
    }
}

extension FromBuilder {
    public static func buildExpression(_ expression: JoinBuilder.JoinSourceAliased) -> JoinBuilder.JoinSourceAliased {
        expression
    }

    public static func buildExpression(_ expression: JoinBuilder.JoinOpen) -> JoinBuilder.JoinOpen {
        expression
    }

    /// A JOIN continues the immediately preceding FROM source in the same item.
    public static func buildPartialBlock<Attachment: AttachmentState, Current: CurrentState>(
        accumulated: Partial<Attachment, Current>,
        next: JoinBuilder.JoinOpen
    ) -> Partial<Attachment, JoinBuilder.JoinOpen> {
        Partial(
            completed: accumulated.completed,
            current: next.addingBaseSource(accumulated.current.finalize().parts)
        )
    }

    /// A fluent/operator alias is received already in the same typed phase as sibling `As`.
    public static func buildPartialBlock<Attachment: AttachmentState, Current: CurrentState>(
        accumulated: Partial<Attachment, Current>,
        next: JoinBuilder.JoinSourceAliased
    ) -> Partial<Attachment, JoinBuilder.JoinSourceAliased> {
        Partial(
            completed: accumulated.completed,
            current: next.addingBaseSource(accumulated.current.finalize().parts)
        )
    }

    public static func buildExpression(_ request: JoinBuilder.OnRequest) -> JoinBuilder.OnRequest {
        request
    }

    public static func buildExpression(_ request: JoinBuilder.UsingRequest) -> JoinBuilder.UsingRequest {
        request
    }

    public static func buildPartialBlock<Attachment: AttachmentState>(
        accumulated: Partial<Attachment, JoinBuilder.JoinOpen>,
        next: JoinBuilder.OnRequest
    ) -> Partial<Attachment, JoinBuilder.JoinOnQualified> {
        Partial(
            completed: accumulated.completed,
            current: accumulated.current.addingOn(next.parts)
        )
    }

    public static func buildPartialBlock<Attachment: AttachmentState>(
        accumulated: Partial<Attachment, JoinBuilder.JoinSourceAliased>,
        next: JoinBuilder.OnRequest
    ) -> Partial<Attachment, JoinBuilder.JoinOnQualified> {
        Partial(
            completed: accumulated.completed,
            current: accumulated.current.addingOn(next.parts)
        )
    }

    public static func buildPartialBlock<Attachment: AttachmentState>(
        accumulated: Partial<Attachment, JoinBuilder.JoinOpen>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<Attachment, JoinBuilder.JoinUsing> {
        Partial(
            completed: accumulated.completed,
            current: accumulated.current.addingUsing(next.names)
        )
    }

    public static func buildPartialBlock<Attachment: AttachmentState>(
        accumulated: Partial<Attachment, JoinBuilder.JoinSourceAliased>,
        next: JoinBuilder.UsingRequest
    ) -> Partial<Attachment, JoinBuilder.JoinUsing> {
        Partial(
            completed: accumulated.completed,
            current: accumulated.current.addingUsing(next.names)
        )
    }

    public static func buildPartialBlock<Attachment: AttachmentState>(
        accumulated: Partial<Attachment, JoinBuilder.JoinUsing>,
        next: SQLBuilder.AliasRequest
    ) -> Partial<Attachment, JoinBuilder.JoinUsingAliased> {
        Partial(completed: accumulated.completed, current: accumulated.current.addingAlias(next.name))
    }
}
