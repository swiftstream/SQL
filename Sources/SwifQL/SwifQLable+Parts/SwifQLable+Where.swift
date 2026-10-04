//
//  SQLable+Where.swift
//  SQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

//MARK: Where

extension SQLable {
    public var `where`: SQLable {
        structurallyAppending(SQLableParts(parts: [SQLPartOperator.space, .where]))
    }
    public func `where`(_ predicates: SQLable) -> SQLable {
        let parts = [SQLPartOperator.space, .where, .space] + predicates.parts
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
