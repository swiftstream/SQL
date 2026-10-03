//
//  SwifQLable+Timestamp.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: Timestamp

extension SwifQLable {
    public var timestamp: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .timestamp)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    public func timestamp(_ fields: SwifQLable...) -> SwifQLable {
        timestamp(fields)
    }
    public func timestamp(_ fields: [SwifQLable]) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .timestamp)
        parts.append(o: .space)
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
