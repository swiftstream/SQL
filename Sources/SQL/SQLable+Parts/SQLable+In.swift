//
//  SQLable+In.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: IN

extension SQLable {
    /// Builds query with `IN` parameter
    ///
    /// Example usage:
    /// ```swift
    /// SQL.select
    ///     // ...
    ///     .where((\User.$id).in(aUserID, bUserID))
    /// ```
    /// - Parameter items: comma separated list of  `SQLable` elements
    ///
    public func `in`(_ items: SQLable...) -> SQLable {
        `in`(items)
    }

    /// Builds query with `IN` parameter
    ///
    /// Example usage:
    /// ```swift
    /// SQL.select
    ///     // ...
    ///     .where((\User.$id).in(userIDsArray))
    /// ```
    /// - Parameter items: Array of `[SQLable]` elements
    ///
    public func `in`(_ items: [SQLable]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .in)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        if items.count == 1, let array = items.first as? AnySQLEnumArray {
            array.items.enumerated().forEach { i, v in
                if i > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(safe: v.anyRawValue)
            }
        } else {
            items.enumerated().forEach { i, v in
                if i > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(contentsOf: v.parts)
            }
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
