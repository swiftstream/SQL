//
//  SQLable+Constraint.swift
//  SwifQL
//
//  Created by Mihael Isaev on 24/07/2019.
//

import Foundation

//MARK: Constraint

extension SQLable {
    public var constraint: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .constraint)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func constraint(_ value: KeyPathLastPath) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .constraint)
        parts.append(o: .space)
        parts.append(SQLPartAlias(value.lastPath))
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

