//
//  SQLable+And.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: AND

extension SQLable {
    public var and: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .and)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func and(_ predicate: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .and)
        parts.append(o: .space)
        parts.append(contentsOf: predicate.parts)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
