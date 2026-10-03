//
//  SwifQLable+Conflict.swift
//  SwifQL
//
//  Created by Mihael Isaev on 24/07/2019.
//

import Foundation

//MARK: Conflict

extension SwifQLable {
    public var conflict: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .conflict)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func conflict(_ paths: KeyPathLastPath...) -> SwifQLable {
        conflict(paths)
    }
    
    public func conflict(_ paths: [KeyPathLastPath]) -> SwifQLable {
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
            parts.append(SwifQLPartAlias(p.lastPath))
        }
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
