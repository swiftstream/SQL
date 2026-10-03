//
//  SwifQLable+NotILike.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

// MARK: NOT ILIKE

extension SwifQLable {
    /// Builds query with `NOT ILIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SwifQL.select
    ///     // ...
    ///     .where((\User.$name).notILike(name))
    /// ```
    /// - Parameter part: `SwifQLable` element
    ///
    public func notILike(_ part: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .notILike)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
