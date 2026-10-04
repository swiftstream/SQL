import Foundation

private func groupingExpressionParts(
    _ keyword: String,
    expressions: [[SQLPart]]
) -> [SQLPart] {
    var parts: [SQLPart] = [
        SQLPartOperator.custom(keyword),
        SQLPartOperator.openBracket
    ]

    for (index, expression) in expressions.enumerated() {
        if index > 0 {
            parts.append(o: .comma, .space)
        }
        parts.append(contentsOf: expression)
    }

    parts.append(o: .closeBracket)
    return parts
}

private func groupingSetParts(_ sets: [[[SQLPart]]]) -> [SQLPart] {
    var parts: [SQLPart] = [
        SQLPartOperator.custom("GROUPING"),
        SQLPartOperator.space,
        SQLPartOperator.custom("SETS"),
        SQLPartOperator.space,
        SQLPartOperator.openBracket
    ]

    for (setIndex, set) in sets.enumerated() {
        if setIndex > 0 {
            parts.append(o: .comma, .space)
        }
        parts.append(o: .openBracket)
        for (expressionIndex, expression) in set.enumerated() {
            if expressionIndex > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: expression)
        }
        parts.append(o: .closeBracket)
    }

    parts.append(o: .closeBracket)
    return parts
}

/// A GROUP BY grouping-set expression.
public struct GroupingSets: SQLable {
    private let sets: [[[SQLPart]]]

    public init(_ sets: [SQLable]...) {
        self.init(sets)
    }

    public init(_ sets: [[SQLable]]) {
        self.sets = sets.map { set in
            set.map(\.parts)
        }
    }

    public var parts: [SQLPart] {
        groupingSetParts(sets)
    }
}

/// A ROLLUP grouping expression for the existing GROUP BY clause.
public struct Rollup: SQLable {
    private let expressions: [[SQLPart]]

    public init(_ expression: SQLable, _ expressions: SQLable...) {
        self.expressions = ([expression] + expressions).map(\.parts)
    }

    public init(_ expressions: [SQLable]) {
        self.expressions = expressions.map(\.parts)
    }

    public var parts: [SQLPart] {
        groupingExpressionParts("ROLLUP", expressions: expressions)
    }
}

/// A CUBE grouping expression for the existing GROUP BY clause.
public struct Cube: SQLable {
    private let expressions: [[SQLPart]]

    public init(_ expression: SQLable, _ expressions: SQLable...) {
        self.expressions = ([expression] + expressions).map(\.parts)
    }

    public init(_ expressions: [SQLable]) {
        self.expressions = expressions.map(\.parts)
    }

    public var parts: [SQLPart] {
        groupingExpressionParts("CUBE", expressions: expressions)
    }
}
