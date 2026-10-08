//
//  SQLArray.swift
//  SQL
//

import Foundation

/// Exact SQL ARRAY constructor namespace.
///
/// This is intentionally distinct from Swift.Array and from the historical
/// dialect-polymorphic SQLPartArray compatibility path.
public struct SQLArray {}

/// Ordered ARRAY element snapshots produced by SQLArrayItemsBuilder.
public struct SQLArrayItems {
    let elementParts: [[SQLPart]]

    init(elementParts: [[SQLPart]] = []) {
        self.elementParts = elementParts
    }
}

@resultBuilder
public enum SQLArrayItemsBuilder {
    public static func buildExpression(_ expression: any SQLable) -> SQLArrayItems {
        SQLArrayItems(elementParts: [expression.parts])
    }

    public static func buildBlock() -> SQLArrayItems {
        SQLArrayItems()
    }

    public static func buildBlock(_ components: SQLArrayItems...) -> SQLArrayItems {
        SQLArrayItems(elementParts: components.flatMap(\.elementParts))
    }

    public static func buildOptional(_ component: SQLArrayItems?) -> SQLArrayItems {
        component ?? SQLArrayItems()
    }

    public static func buildEither(first component: SQLArrayItems) -> SQLArrayItems {
        component
    }

    public static func buildEither(second component: SQLArrayItems) -> SQLArrayItems {
        component
    }

    public static func buildArray(_ components: [SQLArrayItems]) -> SQLArrayItems {
        SQLArrayItems(elementParts: components.flatMap(\.elementParts))
    }
}

extension SQLArray {
    public static func items(_ values: any SQLable...) -> SQLable {
        lowerItems(values.map { $0.parts })
    }

    public static func items(
        @SQLArrayItemsBuilder _ body: () -> SQLArrayItems
    ) -> SQLable {
        lowerItems(body().elementParts)
    }

    public static func subquery(_ query: any SQLable) -> SQLable {
        let queryParts = query.parts
        return lowerSubquery(queryParts)
    }

    public static func subquery(
        @SQLBuilder _ body: () -> SQLContent
    ) -> SQLable {
        let query = body()
        let queryParts = query.parts
        return lowerSubquery(queryParts)
    }

    private static func lowerItems(_ elements: [[SQLPart]]) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.array,
            SQLPartOperator.openSquareBracket
        ]

        for (index, elementParts) in elements.enumerated() {
            if index > 0 {
                parts.append(SQLPartOperator.comma)
                parts.append(SQLPartOperator.space)
            }
            parts.append(contentsOf: elementParts)
        }

        parts.append(SQLPartOperator.closeSquareBracket)
        return SQLableParts(rawParts: parts)
    }

    private static func lowerSubquery(_ queryParts: [SQLPart]) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.array,
            SQLPartOperator.openBracket
        ]
        parts.append(contentsOf: queryParts)
        parts.append(SQLPartOperator.closeBracket)
        return SQLableParts(rawParts: parts)
    }
}
