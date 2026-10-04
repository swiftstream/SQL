//
//  SQLable+As.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: AS

extension SQLable {
    public var `as`: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .as)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func `as`(_ type: Type) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .as)
        parts.append(o: .space)
        parts.append(SQLPartType(type))
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    public func `as`(_ expression: SQLable) -> SQLable {
        var parts: [SQLPart] = []
        parts.append(o: .space, .as, .space)
        parts.append(contentsOf: expression.parts)
        return _SQLStructuralComposition.appendingPostfix(parts, to: self)
    }
}
