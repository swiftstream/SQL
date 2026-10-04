//
//  SQLable+Primary.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

//MARK: PRIMARY

extension SQLable {
    public var primary: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .primary)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
