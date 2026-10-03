//
//  SwifQLable+Set.swift
//  
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

//MARK: SET

extension SwifQLable {
    public var set: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .set)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    public func set(_ predicates: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .set)
        parts.append(o: .space)
        parts.append(contentsOf: predicates.parts)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
