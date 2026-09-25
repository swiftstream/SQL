import Foundation

extension JoinBuilder.JoinOpen {
    /// Adds an identifier-safe alias while preserving JOIN continuation ownership.
    public func `as`(_ alias: String) -> JoinBuilder.JoinSourceAliased {
        addingAlias(alias)
    }
}

/// Operator spelling for a typed JOIN source alias.
public func => (
    lhs: JoinBuilder.JoinOpen,
    rhs: String
) -> JoinBuilder.JoinSourceAliased {
    lhs.as(rhs)
}

/// Requests a typed JOIN source that can be continued by `As`, `On`, or `Using`.
public func Join(_ mode: JoinMode, _ source: SwifQLable) -> JoinBuilder.JoinOpen {
    JoinBuilder.JoinOpen(modeParts: mode.parts, sourceParts: source.parts)
}

/// Requests a nested structural JOIN source, commonly used with a lateral mode.
public func Join(
    _ mode: JoinMode,
    @SQLBuilder _ content: () -> SQLBuilder.Root
) -> JoinBuilder.JoinOpen {
    let query = SQLBuilder.lowerRoot(content().fragments)
    var sourceParts: [SwifQLPart] = []
    sourceParts.append(o: .openBracket)
    sourceParts.append(_SwifQLStructuralComposition.statementFrame(for: query))
    sourceParts.append(o: .closeBracket)
    return JoinBuilder.JoinOpen(modeParts: mode.parts, sourceParts: sourceParts)
}

/// Predicate continuation for the immediately open JOIN item.
public func On(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> JoinBuilder.OnRequest {
    JoinBuilder.OnRequest(parts: body().parts)
}

/// Concise predicate continuation for the immediately open JOIN item.
public func On(_ predicate: SwifQLable) -> JoinBuilder.OnRequest {
    JoinBuilder.OnRequest(parts: predicate.parts)
}

/// Allows the explicit SQL boolean literal form `On(true)`.
public func On(_ predicate: Bool) -> JoinBuilder.OnRequest {
    On(SwifQLBool(predicate))
}

/// Structural last-path identifier list for a JOIN USING continuation.
public func Using(
    _ first: KeyPathLastPath,
    _ rest: KeyPathLastPath...
) -> JoinBuilder.UsingRequest {
    JoinBuilder.UsingRequest(names: ([first] + rest).map(\.lastPath))
}
