//
//  SQLable+NotILike.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

// MARK: NOT ILIKE

extension SQLable {
    /// Builds query with `NOT ILIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SQL.root.select
    ///     // ...
    ///     .where((\User.$name).notILike(name))
    /// ```
    /// - Parameter part: `SQLable` element
    ///
    public func notILike(_ part: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .notILike)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
