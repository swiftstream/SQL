//
//  StarModifiers.swift
//  SwifQL
//

import Foundation

/// One expression-and-target entry for a star `REPLACE` modifier.
public struct StarReplacement: SQLable {
    public let expressionParts: [SQLPart]
    public let columnName: String

    public init(_ expression: SQLable, as column: KeyPathLastPath) {
        expressionParts = expression.parts
        columnName = column.lastPath
    }

    public var parts: [SQLPart] {
        var parts = expressionParts
        parts.append(o: .space, .as, .space)
        parts.append(SQLPartColumn(columnName))
        return parts
    }
}

/// One old-and-new structural-name entry for a star `RENAME` modifier.
public struct StarRename: SQLable {
    public let oldColumnName: String
    public let newColumnName: String

    public init(_ oldColumn: KeyPathLastPath, to newColumn: KeyPathLastPath) {
        oldColumnName = oldColumn.lastPath
        newColumnName = newColumn.lastPath
    }

    public var parts: [SQLPart] {
        [
            SQLPartColumn(oldColumnName),
            SQLPartOperator.space,
            SQLPartOperator.as,
            SQLPartOperator.space,
            SQLPartColumn(newColumnName)
        ]
    }
}
