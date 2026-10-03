//
//  SwifQLable+Where.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

//MARK: Where

extension SwifQLable {
    public var `where`: SwifQLable {
        structurallyAppending(SwifQLableParts(parts: [SwifQLPartOperator.space, .where]))
    }
    public func `where`(_ predicates: SwifQLable) -> SwifQLable {
        let parts = [SwifQLPartOperator.space, .where, .space] + predicates.parts
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
