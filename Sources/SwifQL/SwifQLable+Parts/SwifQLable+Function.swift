//
//  SQLable+Function.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SQLable {
    public var `function`: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .function)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
