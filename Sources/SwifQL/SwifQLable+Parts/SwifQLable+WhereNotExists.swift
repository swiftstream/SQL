//
//  SwifQLable+WhereNotExists.swift
//  SwifQL
//
//  Created by Mihael Isaev on 23/07/2019.
//

import Foundation

//MARK: Where Not Exists

extension SwifQLable {
    public func whereNotExists(_ predicates: SwifQLable) -> SwifQLable {
        let parts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            .where,
            .space,
            .not,
            .space,
            .exists,
            .space,
            .openBracket,
        ] + predicates.parts + [SwifQLPartOperator.closeBracket]
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
