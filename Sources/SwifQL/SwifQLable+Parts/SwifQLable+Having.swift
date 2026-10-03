//
//  SwifQLable+Having.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: Having

extension SwifQLable {
    public func having(_ predicates: SwifQLable) -> SwifQLable {
        let parts: [SwifQLPart] = [SwifQLPartOperator.space, .having, .space] + predicates.parts
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
