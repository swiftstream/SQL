//
//  SQLable+Null.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: NULL

extension SQLable {

    /// use `null` property to compare column value with `SQL NULL` (aka Swift nil)
    ///
    /// Usage:
    /// ```swift
    /// SQL.select
    ///     // ...
    ///     .where(\User.$name == username
    ///         && |\User.$status == "active" || \User.$updatedAt == SQL.null|)
    /// ```
    public var null: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .null)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
