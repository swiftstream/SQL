//
//  SQLable+Or.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: OR

extension SQLable {
    public func or(_ predicate: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .or)
        parts.append(o: .space)
        parts.append(contentsOf: predicate.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
