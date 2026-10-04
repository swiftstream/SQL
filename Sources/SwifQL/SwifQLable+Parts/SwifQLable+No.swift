//
//  SQLable+No.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: NO

extension SQLable {
    public var no: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .no)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

