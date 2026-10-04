//
//  SQLable+Commit.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

//MARK: COMMIT

extension SQLable {
    public var commit: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .commit)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
