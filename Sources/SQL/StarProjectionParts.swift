//
//  StarProjectionParts.swift
//  SwifQL
//

import Foundation

/// Structural column names excluded from a star projection.
public struct SQLStarExcludePart: SQLPart, SQLSemanticRoleCarryingPart {
    public let columnNames: [String]
    public let semanticRole: SQLSemanticRole?

    init(columnNames: [String], semanticRole: SQLSemanticRole?) {
        self.columnNames = columnNames
        self.semanticRole = semanticRole
    }
}

/// Structural expression-and-target entries replacing columns in a star projection.
public struct SQLStarReplacePart: SQLPart, SQLSemanticRoleCarryingPart {
    public let entries: [StarReplacement]
    public let semanticRole: SQLSemanticRole?

    init(entries: [StarReplacement], semanticRole: SQLSemanticRole?) {
        self.entries = entries
        self.semanticRole = semanticRole
    }
}

/// Structural old-and-new column names in a star projection rename.
public struct SQLStarRenamePart: SQLPart, SQLSemanticRoleCarryingPart {
    public let entries: [StarRename]
    public let semanticRole: SQLSemanticRole?

    init(entries: [StarRename], semanticRole: SQLSemanticRole?) {
        self.entries = entries
        self.semanticRole = semanticRole
    }
}
