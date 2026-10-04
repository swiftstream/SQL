//
//  SQLable+If.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: IF

extension SQLable {
    public var `if`: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .if)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
