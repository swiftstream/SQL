//
//  SQLable+Cascade.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: CASCADE

extension SQLable {
    public var cascade: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .cascade)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
