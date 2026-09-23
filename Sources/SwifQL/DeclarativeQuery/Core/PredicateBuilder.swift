import Foundation

/// Reusable predicate result builder with default SQL `AND` composition.
///
/// Surviving direct children are joined with `AND`. Empty dynamic sources
/// contribute no parts and never synthesize `TRUE` / `FALSE` / empty parentheses.
@resultBuilder
public enum PredicateBuilder {
    /// Public builder product for reusable clause owners.
    ///
    /// Storage is module-internal only; ordinary call sites receive this type
    /// from the builder and consume it as `SwifQLable`.
    public struct Components: SwifQLable {
        let fragments: [[SwifQLPart]]

        init(fragments: [[SwifQLPart]]) {
            self.fragments = fragments
        }

        public var parts: [SwifQLPart] {
            _PredicateComposition.join(fragments, with: .and, parenthesized: false)
        }
    }

    public static func buildExpression(
        _ expression: SwifQLable
    ) -> Components {
        let snapshot = expression.parts
        guard !snapshot.isEmpty else {
            return Components(fragments: [])
        }
        return Components(fragments: [snapshot])
    }

    public static func buildBlock(
        _ components: Components...
    ) -> Components {
        Components(fragments: components.flatMap { $0.fragments })
    }

    public static func buildOptional(
        _ component: Components?
    ) -> Components {
        component ?? Components(fragments: [])
    }

    public static func buildEither(
        first component: Components
    ) -> Components {
        component
    }

    public static func buildEither(
        second component: Components
    ) -> Components {
        component
    }

    public static func buildArray(
        _ components: [Components]
    ) -> Components {
        Components(fragments: components.flatMap { $0.fragments })
    }
}

/// Narrow internal ordinary-parts join helper.
///
/// Operates only on snapshotted `[SwifQLPart]` fragments. It does not create a
/// second AST, scan rendered SQL, infer ownership from prior operator tokens,
/// or hold ambient mutable state.
enum _PredicateComposition {
    static func join(
        _ fragments: [[SwifQLPart]],
        with operator: SwifQLPartOperator,
        parenthesized: Bool
    ) -> [SwifQLPart] {
        let surviving = fragments.filter { !$0.isEmpty }
        guard !surviving.isEmpty else {
            return []
        }

        if surviving.count == 1, !parenthesized {
            return surviving[0]
        }

        var parts: [SwifQLPart] = []
        if parenthesized {
            parts.append(o: .openBracket)
        }
        for (index, fragment) in surviving.enumerated() {
            if index > 0 {
                parts.append(o: .space)
                parts.append(o: `operator`)
                parts.append(o: .space)
            }
            parts.append(contentsOf: fragment)
        }
        if parenthesized {
            parts.append(o: .closeBracket)
        }
        return parts
    }
}

/// Explicit grouped `AND` composition with owned parentheses.
///
/// Non-empty groups always render `( ... )`. Empty groups contribute no parts.
public func And(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> SwifQLable {
    let joined = _PredicateComposition.join(
        body().fragments,
        with: .and,
        parenthesized: true
    )
    return SwifQLableParts(rawParts: joined)
}

/// Explicit grouped `OR` composition with owned parentheses.
///
/// Non-empty groups always render `( ... )`. Empty groups contribute no parts.
public func Or(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> SwifQLable {
    let joined = _PredicateComposition.join(
        body().fragments,
        with: .or,
        parenthesized: true
    )
    return SwifQLableParts(rawParts: joined)
}
