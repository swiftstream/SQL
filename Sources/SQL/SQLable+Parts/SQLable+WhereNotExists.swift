//
//  SQLable+WhereNotExists.swift
//  SwifQL
//
//  Created by Mihael Isaev on 23/07/2019.
//

import Foundation

//MARK: Where Not Exists

extension SQLable {
    public func whereNotExists(_ predicates: SQLable) -> SQLable {
        let parts: [SQLPart] = [
            SQLPartOperator.space,
            .where,
            .space,
            .not,
            .space,
            .exists,
            .space,
            .openBracket,
        ] + predicates.parts + [SQLPartOperator.closeBracket]
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
