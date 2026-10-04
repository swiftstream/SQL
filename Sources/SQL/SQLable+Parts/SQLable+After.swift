//
//  SQLable+After.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

//MARK: AFTER

extension SQLable {
    public var after: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .after)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
