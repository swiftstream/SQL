//
//  SQLable+Overlaps.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: Overlaps

extension SQLable {
    public var overlaps: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .overlaps)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    public func overlaps(_ fields: SQLable...) -> SQLable {
        overlaps(fields)
    }
    
    public func overlaps(_ fields: [SQLable]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .overlaps)
        if fields.count > 0 {
            parts.append(o: .space)
            parts.append(o: .openBracket)
        }
        for (i, v) in fields.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        if fields.count > 0 {
            parts.append(o: .closeBracket)
        }
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
