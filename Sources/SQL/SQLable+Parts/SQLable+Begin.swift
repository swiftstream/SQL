//
//  SQLable+Begin.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: BEGIN

extension SQLable {
    public var begin: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .begin)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
