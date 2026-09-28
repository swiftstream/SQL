import Foundation

/// A typed WHERE request consumed only by an open declarative SELECT owner.
public struct WhereClause {
    let predicateParts: [SwifQLPart]

    init(predicateParts: [SwifQLPart]) {
        self.predicateParts = predicateParts
    }
}

/// A typed HAVING request consumed only by an open declarative SELECT owner.
public struct HavingClause {
    let predicateParts: [SwifQLPart]

    init(predicateParts: [SwifQLPart]) {
        self.predicateParts = predicateParts
    }
}

/// A typed QUALIFY request consumed only by an open declarative SELECT owner.
public struct QualifyClause {
    let predicateParts: [SwifQLPart]

    init(predicateParts: [SwifQLPart]) {
        self.predicateParts = predicateParts
    }
}

/// A typed GROUP BY request consumed only by an open declarative SELECT owner.
public struct GroupByClause {
    let expressionParts: [[SwifQLPart]]

    init(expressionParts: [[SwifQLPart]]) {
        self.expressionParts = expressionParts
    }
}

/// A typed ORDER BY request consumed only by an open declarative SELECT owner.
public struct OrderByClause {
    let items: [OrderByItem]

    init(items: [OrderByItem]) {
        self.items = items.compactMap { item in
            let elements = item.elements
                .map { SwifQLableParts(rawParts: $0.parts) }
                .filter { !$0.parts.isEmpty }
            guard !elements.isEmpty else { return nil }
            return OrderByItem(elements: elements, direction: item.direction, nulls: item.nulls)
        }
    }
}

/// A typed LIMIT request consumed only by an open declarative SELECT owner.
public struct LimitClause {
    let countParts: [SwifQLPart]

    init(countParts: [SwifQLPart]) {
        self.countParts = countParts
    }
}

/// A typed OFFSET request consumed only by an open declarative SELECT owner.
public struct OffsetClause {
    let countParts: [SwifQLPart]

    init(countParts: [SwifQLPart]) {
        self.countParts = countParts
    }
}

/// Creates a WHERE clause request using the established predicate grammar.
public func Where(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> WhereClause {
    WhereClause(predicateParts: body().parts)
}

/// Creates a HAVING clause request using the established predicate grammar.
public func Having(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> HavingClause {
    HavingClause(predicateParts: body().parts)
}

/// Creates a QUALIFY clause request using the established predicate grammar.
public func Qualify(
    @PredicateBuilder _ body: () -> PredicateBuilder.Components
) -> QualifyClause {
    QualifyClause(predicateParts: body().parts)
}

/// Creates a GROUP BY request using the existing grouping expression grammar.
public func GroupBy(
    @GroupByBuilder _ body: () -> GroupByBuilder.Result
) -> GroupByClause {
    GroupByClause(expressionParts: body().expressionParts)
}

/// Creates an ORDER BY request using existing `OrderByItem` values.
public func OrderBy(
    @OrderByBuilder _ body: () -> OrderByBuilder.Result
) -> OrderByClause {
    OrderByClause(items: body().items)
}

/// Creates a concise single-expression ORDER BY request.
public func OrderBy(
    _ expression: any SwifQLable,
    _ direction: OrderByItem.Direction
) -> OrderByClause {
    OrderByClause(items: [OrderByItem.direction(direction, expression)])
}

/// Creates a LIMIT request. Empty `parts` omit the whole clause at its owner.
public func Limit(_ count: any SwifQLable) -> LimitClause {
    LimitClause(countParts: count.parts)
}

/// Creates an OFFSET request. Empty `parts` omit the whole clause at its owner.
public func Offset(_ count: any SwifQLable) -> OffsetClause {
    OffsetClause(countParts: count.parts)
}
