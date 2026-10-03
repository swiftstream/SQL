//
//  SwifQLable+Rollback.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

//MARK: ROLLBACK

extension SwifQLable {
    public var rollback: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .rollback)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
