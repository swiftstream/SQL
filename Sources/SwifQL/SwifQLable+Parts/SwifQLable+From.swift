//
//  SwifQLable+From.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

//MARK: From

extension SwifQLable {
    public func from(_ tables: SwifQLable...) -> SwifQLable {
        from(tables)
    }
    public func from(_ tables: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.from,
            SwifQLPartOperator.space
        ]
        for (i, v) in tables.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
