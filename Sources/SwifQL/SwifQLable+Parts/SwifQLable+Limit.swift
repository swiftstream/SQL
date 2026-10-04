//
//  SQLable+Limit.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: LIMIT

extension SQLable {
    public func limit(_ value: SQLable) -> SQLable {
        let parts: [SQLPart] = [SQLPartOperator.space, SQLPartOperator.limit, SQLPartOperator.space] + value.parts
        return structurallyAppending(SQLableParts(parts: parts))
    }

    /// Appends DuckDB's exact percentage LIMIT form without changing the
    /// established row-count overload.
    public func limit(percent value: SQLable) -> SQLable {
        var parts: [SQLPart] = [SQLPartOperator.space, SQLPartOperator.limit, SQLPartOperator.space]
        parts.append(contentsOf: value.parts)
        parts.append(SQLPartOperator.custom("%"))
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
