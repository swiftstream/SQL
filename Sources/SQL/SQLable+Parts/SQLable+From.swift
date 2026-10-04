//
//  SQLable+From.swift
//  SQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

//MARK: From

extension SQLable {
    public func from(_ tables: SQLable...) -> SQLable {
        from(tables)
    }
    public func from(_ tables: [SQLable]) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.from,
            SQLPartOperator.space
        ]
        for (i, v) in tables.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
