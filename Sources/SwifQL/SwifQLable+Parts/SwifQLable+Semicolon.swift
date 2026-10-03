//
//  SwifQLable+Semicolon.swift
//  
//
//  Created by Mihael Isaev on 24.01.2020.
//

import Foundation

extension SwifQLable {
    /// Represent just `;` symbol
    public var semicolon: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.append(o: .semicolon)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
