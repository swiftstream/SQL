//
//  SQLable+Rollback.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

//MARK: ROLLBACK

extension SQLable {
    public var rollback: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .rollback)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
