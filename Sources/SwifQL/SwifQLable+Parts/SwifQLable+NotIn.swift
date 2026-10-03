//
//  SwifQLable+NotIn.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

// MARK: IN

extension SwifQLable {
    /// Builds query with `NOT IN` parameter
    ///
    /// Example usage:
    /// ```swift
    /// SwifQL.select
    ///     // ...
    ///     .where((\User.$id).notIn(aUserID, bUserID))
    /// ```
    /// - Parameter items: comma separated list of  `SwifQLable` elements
    ///
    public func notIn(_ items: SwifQLable...) -> SwifQLable {
        notIn(items)
    }

    /// Builds query with `NOT IN` parameter
    ///
    /// Example usage:
    /// ```swift
    /// SwifQL.select
    ///     // ...
    ///     .where((\User.$id).notIn(userIDsArray))
    /// ```
    /// - Parameter items: Array of `[SwifQLable]` elements
    ///
    public func notIn(_ items: [SwifQLable]) -> SwifQLable {
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
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
