//
//  SQLable+Offset.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: OFFSET

extension SQLable {
    public func offset(_ value: SQLable) -> SQLable {
        let parts: [SQLPart] = [SQLPartOperator.space, .offset, .space] + value.parts
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
