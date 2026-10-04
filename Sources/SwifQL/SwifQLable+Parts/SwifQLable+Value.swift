//
//  SQLable+Value.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

extension SQLable {
    public subscript (any item: SQLable) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(contentsOf: item.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    /// Represent just `VALUE` keyword
    public var value: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .value)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    /// Represent `VALUE _` where _ is provided item
    public func value(_ item: SQLable) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .value)
        parts.append(o: .space)
        parts.append(contentsOf: item.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
