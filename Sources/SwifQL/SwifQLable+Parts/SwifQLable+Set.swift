//
//  SQLable+Set.swift
//  
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

//MARK: SET

extension SQLable {
    public var set: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .set)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    public func set(_ predicates: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .set)
        parts.append(o: .space)
        parts.append(contentsOf: predicates.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
