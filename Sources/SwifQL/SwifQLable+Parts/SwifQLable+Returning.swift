//
//  SwifQLable+Returning.swift
//  SwifQL
//
//  Created by Mihael Isaev on 11/07/2019.
//

import Foundation

extension SwifQLable {
    public var returning: SwifQLable {
        return structurallyAppending(SwifQLableParts(parts: [
            SwifQLPartOperator.space,
            .returning,
        ]))
    }
    
    public func returning(_ paths: KeyPathLastPath...) -> SwifQLable {
        returning(paths)
    }
    
    public func returning(_ paths: [KeyPathLastPath]) -> SwifQLable {
        var parts: [SwifQLPart] = [
            SwifQLPartOperator.space,
            SwifQLPartOperator.returning,
            SwifQLPartOperator.space,
        ]
        for (i, p) in paths.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(SwifQLPartAlias(p.lastPath))
        }
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
