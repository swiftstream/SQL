//
//  SQLable+WhereExists.swift
//  SwifQL
//
//  Created by Mihael Isaev on 23/07/2019.
//

import Foundation

//MARK: Where Exists

extension SQLable {
    public func whereExists(_ predicates: SQLable) -> SQLable {
        let parts: [SQLPart] = [
            SQLPartOperator.space,
            .where,
            .space,
            .exists,
            .space,
            .openBracket,
        ] + predicates.parts + [SQLPartOperator.closeBracket]
        return structurallyAppending(SQLableParts(parts: parts))
    }
}