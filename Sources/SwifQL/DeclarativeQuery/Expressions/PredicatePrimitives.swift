import Foundation

/// Explicit `IS NULL` predicate node.
///
/// Exact semantic equivalent of `expression == nil` and `expression.isNull`.
/// Reuses the existing predicate/operator parts; the NULL keyword itself binds
/// no values.
public func IsNull(_ expression: SwifQLable) -> SwifQLable {
    SwifQLPredicate(operator: .equal, lhs: expression, rhs: nil)
}

/// Explicit `IS NOT NULL` predicate node.
///
/// Exact semantic equivalent of `expression != nil` and `expression.isNotNull`.
/// Reuses the existing predicate/operator parts; the NULL keyword itself binds
/// no values.
public func IsNotNull(_ expression: SwifQLable) -> SwifQLable {
    SwifQLPredicate(operator: .notEqual, lhs: expression, rhs: nil)
}

/// Declarative runtime-collection `IN` with predicate-presence omission.
///
/// An empty collection contributes no predicate fragment: it does not render
/// `lhs`, `IN ()`, `TRUE`/`FALSE`, and does not bind values. Non-empty input
/// snapshots `lhs` and each element exactly once in collection iteration order,
/// then lowers through the existing legacy membership part semantics.
public func In<C: Collection>(
    _ lhs: SwifQLable,
    _ items: C
) -> SwifQLable where C.Element: SwifQLable {
    guard !items.isEmpty else {
        return SwifQLableParts(rawParts: [])
    }

    let lhsSnapshot = SwifQLableParts(rawParts: lhs.parts)
    let itemSnapshots: [SwifQLable] = items.map { item in
        SwifQLableParts(rawParts: item.parts)
    }
    return lhsSnapshot.in(itemSnapshots)
}

/// Declarative runtime-collection `NOT IN` with predicate-presence omission.
///
/// An empty collection contributes no predicate fragment: it does not render
/// `lhs`, `NOT IN ()`, `TRUE`/`FALSE`, and does not bind values. Non-empty input
/// snapshots `lhs` and each element exactly once in collection iteration order,
/// then lowers through the existing legacy membership part semantics.
public func NotIn<C: Collection>(
    _ lhs: SwifQLable,
    _ items: C
) -> SwifQLable where C.Element: SwifQLable {
    guard !items.isEmpty else {
        return SwifQLableParts(rawParts: [])
    }

    let lhsSnapshot = SwifQLableParts(rawParts: lhs.parts)
    let itemSnapshots: [SwifQLable] = items.map { item in
        SwifQLableParts(rawParts: item.parts)
    }
    return lhsSnapshot.notIn(itemSnapshots)
}
