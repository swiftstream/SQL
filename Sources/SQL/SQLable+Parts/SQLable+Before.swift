//
//  SQLable+Before.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

//MARK: BEFORE

extension SQLable {
    public var before: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .before)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
