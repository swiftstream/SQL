//
//  SwifQLable+Overlaps.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: Overlaps

extension SwifQLable {
    public var overlaps: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .overlaps)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    public func overlaps(_ fields: SwifQLable...) -> SwifQLable {
        overlaps(fields)
    }
    
    public func overlaps(_ fields: [SwifQLable]) -> SwifQLable {
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
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}

