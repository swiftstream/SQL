//
//  SQLable+Return.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SQLable {
    public var `return`: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .return)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
