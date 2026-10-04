//
//  SQLable+Select.swift
//  SQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

//MARK: Select

extension SQLable {
    public var select: SQLable {
        structurallyAppending(SQLableParts(parts: [
            SQLPartOperator.space,
            SQLPartOperator.select
        ]))
    }
    
    public func select(_ fields: SQLable...) -> SQLable {
        select(fields)
    }
    
    public func select(_ fields: [SQLable]) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.select,
            SQLPartOperator.space
        ]
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
