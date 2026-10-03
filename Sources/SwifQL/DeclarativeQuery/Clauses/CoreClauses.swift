import Foundation

/// A typed WHERE clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct WhereClause: SwifQLable {
    let predicateParts: [SwifQLPart]

    init(predicateParts: [SwifQLPart]) {
        self.predicateParts = predicateParts
    }

    public var parts: [SwifQLPart] {
        guard !predicateParts.isEmpty else { return [] }
        return SwifQL.`where`(SwifQLableParts(rawParts: predicateParts)).parts
    }
}

/// A typed HAVING clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct HavingClause: SwifQLable {
    let predicateParts: [SwifQLPart]

    init(predicateParts: [SwifQLPart]) {
        self.predicateParts = predicateParts
    }

    public var parts: [SwifQLPart] {
        guard !predicateParts.isEmpty else { return [] }
        return SwifQL.having(SwifQLableParts(rawParts: predicateParts)).parts
    }
}

/// A typed QUALIFY clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct QualifyClause: SwifQLable {
    let predicateParts: [SwifQLPart]

    init(predicateParts: [SwifQLPart]) {
        self.predicateParts = predicateParts
    }

    public var parts: [SwifQLPart] {
        guard !predicateParts.isEmpty else { return [] }
        return SwifQL.qualify(SwifQLableParts(rawParts: predicateParts)).parts
    }
}

/// A typed GROUP BY clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct GroupByClause: SwifQLable {
    let expressionParts: [[SwifQLPart]]

    init(expressionParts: [[SwifQLPart]]) {
        self.expressionParts = expressionParts
    }

    public var parts: [SwifQLPart] {
        let expressions = expressionParts.filter { !$0.isEmpty }
        guard !expressions.isEmpty else { return [] }
        return SwifQL.groupBy(expressions.map { SwifQLableParts(rawParts: $0) as SwifQLable }).parts
    }
}

/// A typed ORDER BY clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct OrderByClause: SwifQLable {
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

    public var parts: [SwifQLPart] {
        guard !items.isEmpty else { return [] }
        return SwifQL.orderBy(items).parts
    }
}

/// A typed LIMIT clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct LimitClause: SwifQLable {
    let countParts: [SwifQLPart]

    init(countParts: [SwifQLPart]) {
        self.countParts = countParts
    }

    public var parts: [SwifQLPart] {
        guard !countParts.isEmpty else { return [] }
        return SwifQL.limit(SwifQLableParts(rawParts: countParts)).parts
    }
}

/// A typed OFFSET clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct OffsetClause: SwifQLable {
    let countParts: [SwifQLPart]

    init(countParts: [SwifQLPart]) {
        self.countParts = countParts
    }

    public var parts: [SwifQLPart] {
        guard !countParts.isEmpty else { return [] }
        return SwifQL.offset(SwifQLableParts(rawParts: countParts)).parts
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

/// Creates a LIMIT request. Empty `parts` render as an empty fragment, omitting the clause.
public func Limit(_ count: any SwifQLable) -> LimitClause {
    LimitClause(countParts: count.parts)
}

/// Creates an OFFSET request. Empty `parts` render as an empty fragment, omitting the clause.
public func Offset(_ count: any SwifQLable) -> OffsetClause {
    OffsetClause(countParts: count.parts)
}
