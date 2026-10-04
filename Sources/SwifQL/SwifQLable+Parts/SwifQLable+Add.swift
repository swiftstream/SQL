//
//  SQLable+Add.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

extension SQLable {
    public var add: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .add)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
