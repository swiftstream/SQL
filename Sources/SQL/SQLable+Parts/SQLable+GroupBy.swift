//
//  SQLable+GroupBy.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: GROUP BY

extension SQLable {
    public func groupBy(_ fields: SQLable...) -> SQLable {
        groupBy(fields)
    }
    public func groupBy(_ fields: [SQLable]) -> SQLable {
        let clause = SQLGroupByPart(
            owner: structuralOwner(for: .groupBy),
            fields: fields.map(\.parts)
        )
        let fragment = SQLableParts(parts: [SQLPartOperator.space, clause])
        return structurallyAppending(fragment)
    }
}
