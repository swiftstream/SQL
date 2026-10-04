//
//  SQLable+NotIn.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

// MARK: IN

extension SQLable {
    /// Builds query with `NOT IN` parameter
    ///
    /// Example usage:
    /// ```swift
    /// SQL.root.select
    ///     // ...
    ///     .where((\User.$id).notIn(aUserID, bUserID))
    /// ```
    /// - Parameter items: comma separated list of  `SQLable` elements
    ///
    public func notIn(_ items: SQLable...) -> SQLable {
        notIn(items)
    }

    /// Builds query with `NOT IN` parameter
    ///
    /// Example usage:
    /// ```swift
    /// SQL.root.select
    ///     // ...
    ///     .where((\User.$id).notIn(userIDsArray))
    /// ```
    /// - Parameter items: Array of `[SQLable]` elements
    ///
    public func notIn(_ items: [SQLable]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .notIn)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        for (i, v) in items.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
