//
//  SQLable+Timestamp.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: Timestamp

extension SQLable {
    public var timestamp: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .timestamp)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    public func timestamp(_ fields: SQLable...) -> SQLable {
        timestamp(fields)
    }
    public func timestamp(_ fields: [SQLable]) -> SQLable {
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
