//
//  SwifQLable+Select.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

//MARK: Select

extension SwifQLable {
    public var select: SwifQLable {
        structurallyAppending(SwifQLableParts(parts: [
            SwifQLPartOperator.space,
            SwifQLPartOperator.select
        ]))
    }
    
    public func select(_ fields: SwifQLable...) -> SwifQLable {
        select(fields)
    }
    
    public func select(_ fields: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.select,
            SwifQLPartOperator.space
        ]
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
