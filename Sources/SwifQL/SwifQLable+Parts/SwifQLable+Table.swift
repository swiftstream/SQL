//
//  SwifQLable+Table.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SwifQLable {
    public var table: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .table)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func table(_ name: String) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .table)
        parts.append(o: .space)
        parts.append(SwifQLPartTable(name))
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
