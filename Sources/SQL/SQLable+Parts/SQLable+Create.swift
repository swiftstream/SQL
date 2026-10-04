//
//  SQLable+CreateType.swift
//  
//
//  Created by Mihael Isaev on 23.01.2020.
//

import Foundation

extension SQLable {
    public var create: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .create)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
