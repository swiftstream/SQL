//
//  SQLable+NotLike.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

// MARK: NOT LIKE

extension SQLable {
    /// Builds query with `NOT LIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SQL.select
    ///     // ...
    ///     .where((\User.$name).notLike(name))
    /// ```
    /// - Parameter part: `SQLable` element
    ///
    public func notLike(_ part: SQLable) -> SQLable {
        applyingPatternOperator(.notLike, to: part)
    }
}
