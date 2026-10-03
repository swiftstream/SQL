//
//  SwifQLable+Rename.swift
//  SwifQL
//
//  Created by Mihael Isaev on 17.08.2020.
//

import Foundation

extension SwifQLable {
    public var column: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .column)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
