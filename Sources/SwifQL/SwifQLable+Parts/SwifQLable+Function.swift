//
//  SwifQLable+Function.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SwifQLable {
    public var `function`: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .function)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
