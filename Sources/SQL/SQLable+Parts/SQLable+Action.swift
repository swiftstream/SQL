//
//  SQLable+Action.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: ACTION

extension SQLable {
    public var action: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .action)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}

