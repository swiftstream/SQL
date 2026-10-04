//
//  SQLable+Key.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: KEY

extension SQLable {
    public var key: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .key)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
