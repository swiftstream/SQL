//
//  SQLable+Rename.swift
//  SwifQL
//
//  Created by Mihael Isaev on 17.08.2020.
//

import Foundation

extension SQLable {
    public var column: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .column)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
