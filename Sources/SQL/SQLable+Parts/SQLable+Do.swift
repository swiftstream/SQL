//
//  SQLable+Do.swift
//  SwifQL
//
//  Created by Mihael Isaev on 24/07/2019.
//

import Foundation

//MARK: Do

extension SQLable {
    public var `do`: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .do)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
