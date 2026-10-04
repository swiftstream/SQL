//
//  SQLable+iLike.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: ILIKE

extension SQLable {
    /// Builds query with `ILIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SQL.root.select
    ///     // ...
    ///     .where((\User.$name).iLike(name))
    /// ```
    /// - Parameter part: `SQLable` element
    ///
    public func iLike(_ part: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .ilike)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
