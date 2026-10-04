//
//  SQLable+Returning.swift
//  SwifQL
//
//  Created by Mihael Isaev on 11/07/2019.
//

import Foundation

extension SQLable {
    public var returning: SQLable {
        return structurallyAppending(SQLableParts(parts: [
            SQLPartOperator.space,
            .returning,
        ]))
    }
    
    public func returning(_ paths: KeyPathLastPath...) -> SQLable {
        returning(paths)
    }
    
    public func returning(_ paths: [KeyPathLastPath]) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.returning,
            SQLPartOperator.space,
        ]
        for (i, p) in paths.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(SQLPartAlias(p.lastPath))
        }
        return structurallyAppending(SQLableParts(parts: parts))
    }
}