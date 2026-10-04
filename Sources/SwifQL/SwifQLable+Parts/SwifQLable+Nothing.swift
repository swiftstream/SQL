//
//  SQLable+Nothing.swift
//  SwifQL
//
//  Created by Mihael Isaev on 24/07/2019.
//

import Foundation

//MARK: Nothing

extension SQLable {
    public var nothing: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .nothing)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
