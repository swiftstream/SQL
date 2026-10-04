//
//  SQLable+Unique.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: UNIQUE

extension SQLable {
    public var unique: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .unique)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
