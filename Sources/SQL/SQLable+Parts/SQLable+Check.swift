//
//  SQLable+Check.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: CHECK

extension SQLable {
    public var check: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .check)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

