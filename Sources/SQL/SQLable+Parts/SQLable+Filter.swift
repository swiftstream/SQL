//
//  SQLable+Filter.swift
//  App
//
//  Created by Mihael Isaev on 01/03/2019.
//

import Foundation

//MARK: Filter

extension SQLable {
    public func filter(where predicates: SQLable...) -> SQLable {
        filter(where: predicates)
    }
    
    public func filter(where predicates: [SQLable]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .filter)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(o: .where)
        parts.append(o: .space)
        predicates.enumerated().forEach { i, v in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
