//
//  SQLable+All.swift
//  App
//
//  Created by Mihael Isaev on 30.09.2021.
//

import Foundation

//MARK: ALL

extension SQLable {
    public var all: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .all)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
