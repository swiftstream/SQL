import Foundation

/// A typed WHERE clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct WhereClause: SQLable {
    let predicateParts: [SQLPart]

    init(predicateParts: [SQLPart]) {
        self.predicateParts = predicateParts
    }

    public var parts: [SQLPart] {
        guard !predicateParts.isEmpty else { return [] }
        return SQL.root.`where`(SQLableParts(rawParts: predicateParts)).parts
    }
}

/// A typed HAVING clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct HavingClause: SQLable {
    let predicateParts: [SQLPart]

    init(predicateParts: [SQLPart]) {
        self.predicateParts = predicateParts
    }

    public var parts: [SQLPart] {
        guard !predicateParts.isEmpty else { return [] }
        return SQL.root.having(SQLableParts(rawParts: predicateParts)).parts
    }
}

/// A typed QUALIFY clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct QualifyClause: SQLable {
    let predicateParts: [SQLPart]

    init(predicateParts: [SQLPart]) {
        self.predicateParts = predicateParts
    }

    public var parts: [SQLPart] {
        guard !predicateParts.isEmpty else { return [] }
        return SQL.root.qualify(SQLableParts(rawParts: predicateParts)).parts
    }
}

/// A typed GROUP BY clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct GroupByClause: SQLable {
    let expressionParts: [[SQLPart]]

    init(expressionParts: [[SQLPart]]) {
        self.expressionParts = expressionParts
    }

    public var parts: [SQLPart] {
        let expressions = expressionParts.filter { !$0.isEmpty }
        guard !expressions.isEmpty else { return [] }
        return SQL.root.groupBy(expressions.map { SQLableParts(rawParts: $0) as SQLable }).parts
    }
}

/// A typed ORDER BY clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct OrderByClause: SQLable {
    let items: [OrderByItem]

    init(items: [OrderByItem]) {
        self.items = items.compactMap { item in
            let elements = item.elements
                .map { SQLableParts(rawParts: $0.parts) }
                .filter { !$0.parts.isEmpty }
            guard !elements.isEmpty else { return nil }
            return OrderByItem(elements: elements, direction: item.direction, nulls: item.nulls)
        }
    }

    public var parts: [SQLPart] {
        guard !items.isEmpty else { return [] }
        return SQL.root.orderBy(items).parts
    }
}

/// A typed LIMIT clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct LimitClause: SQLable {
    let countParts: [SQLPart]

    init(countParts: [SQLPart]) {
        self.countParts = countParts
    }

    public var parts: [SQLPart] {
        guard !countParts.isEmpty else { return [] }
        return SQL.root.limit(SQLableParts(rawParts: countParts)).parts
    }
}

/// A typed OFFSET clause request: an independently renderable SQL fragment
/// that may also participate in specialized local builder composition.
public struct OffsetClause: SQLable {
    let countParts: [SQLPart]

    init(countParts: [SQLPart]) {
        self.countParts = countParts
    }

    public var parts: [SQLPart] {
        guard !countParts.isEmpty else { return [] }
        return SQL.root.offset(SQLableParts(rawParts: countParts)).parts
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
    _ expression: any SQLable,
    _ direction: OrderByItem.Direction
) -> OrderByClause {
    OrderByClause(items: [OrderByItem.direction(direction, expression)])
}

/// Creates a LIMIT request. Empty `parts` render as an empty fragment, omitting the clause.
public func Limit(_ count: any SQLable) -> LimitClause {
    LimitClause(countParts: count.parts)
}

/// Creates an OFFSET request. Empty `parts` render as an empty fragment, omitting the clause.
public func Offset(_ count: any SQLable) -> OffsetClause {
    OffsetClause(countParts: count.parts)
}
