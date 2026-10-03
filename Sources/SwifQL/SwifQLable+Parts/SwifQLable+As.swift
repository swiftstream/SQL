//
//  SwifQLable+As.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: AS

extension SwifQLable {
    public var `as`: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .as)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func `as`(_ type: Type) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .as)
        parts.append(o: .space)
        parts.append(SwifQLPartType(type))
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }

    public func `as`(_ expression: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = []
        parts.append(o: .space, .as, .space)
        parts.append(contentsOf: expression.parts)
        return _SwifQLStructuralComposition.appendingPostfix(parts, to: self)
    }
}
