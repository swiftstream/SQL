//
//  SQLable+Default.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: DEFAULT

extension SQLable {
    public var `default`: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .default)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    public func `default`(_ expression: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .default, .space)
        parts.append(contentsOf: expression.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
