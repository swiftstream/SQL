//
//  SwifQLable+Null.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: NULL

extension SwifQLable {

    /// use `null` property to compare column value with `SQL NULL` (aka Swift nil)
    ///
    /// Usage:
    /// ```swift
    /// SwifQL.select
    ///     // ...
    ///     .where(\User.$name == username
    ///         && |\User.$status == "active" || \User.$updatedAt == SwifQL.null|)
    /// ```
    public var null: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .null)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
