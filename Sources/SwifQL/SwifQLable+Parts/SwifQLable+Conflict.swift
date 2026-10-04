//
//  SQLable+Conflict.swift
//  SwifQL
//
//  Created by Mihael Isaev on 24/07/2019.
//

import Foundation

//MARK: Conflict

extension SQLable {
    public var conflict: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .conflict)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func conflict(_ paths: KeyPathLastPath...) -> SQLable {
        conflict(paths)
    }
    
    public func conflict(_ paths: [KeyPathLastPath]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .conflict)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        for (i, p) in paths.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(SQLPartAlias(p.lastPath))
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
