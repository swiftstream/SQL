//
//  SQLable+End.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: END

extension SQLable {
    public var end: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .end)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
