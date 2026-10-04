//
//  SQLable+Restrict.swift
//  SwifQL
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

//MARK: RESTRICT

extension SQLable {
    public var restrict: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .restrict)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
