//
//  SwifQLable+iLike.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: ILIKE

extension SwifQLable {
    /// Builds query with `ILIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SwifQL.select
    ///     // ...
    ///     .where((\User.$name).iLike(name))
    /// ```
    /// - Parameter part: `SwifQLable` element
    ///
    public func iLike(_ part: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .ilike)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
