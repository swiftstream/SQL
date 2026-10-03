//
//  SwifQLable+Offset.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: OFFSET

extension SwifQLable {
    public func offset(_ value: SwifQLable) -> SwifQLable {
        let parts: [SwifQLPart] = [SwifQLPartOperator.space, .offset, .space] + value.parts
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
