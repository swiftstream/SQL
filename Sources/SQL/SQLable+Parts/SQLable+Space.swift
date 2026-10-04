//
//  SQLable+Space.swift
//  SwifQL
//
//  Created by Mihael Isaev on 31.01.2020.
//

import Foundation

//MARK: simpel whitespace

extension SQLable {
    public var space: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .space)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
