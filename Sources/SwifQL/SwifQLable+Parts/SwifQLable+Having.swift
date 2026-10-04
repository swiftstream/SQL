//
//  SQLable+Having.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: Having

extension SQLable {
    public func having(_ predicates: SQLable) -> SQLable {
        let parts: [SQLPart] = [SQLPartOperator.space, .having, .space] + predicates.parts
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
