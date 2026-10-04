//
//  SQLable+On.swift
//  SwifQL
//
//  Created by Mihael Isaev on 24/07/2019.
//

import Foundation

//MARK: On

extension SQLable {
    public var on: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .on)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
