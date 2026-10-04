//
//  SQLable+Alter.swift
//  SwifQL
//
//  Created by Mihael Isaev on 26/11/2018.
//

import Foundation

//MARK: ALTER

extension SQLable {
    public var alter: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .alter)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
