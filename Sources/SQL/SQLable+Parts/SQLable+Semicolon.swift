//
//  SQLable+Semicolon.swift
//  
//
//  Created by Mihael Isaev on 24.01.2020.
//

import Foundation

extension SQLable {
    /// Represent just `;` symbol
    public var semicolon: SQLable {
        var parts: [SQLPart] = self.parts
        parts.append(o: .semicolon)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
