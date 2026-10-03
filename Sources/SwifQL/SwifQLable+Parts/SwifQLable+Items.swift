//
//  SwifQLable+Items.swift
//  App
//
//  Created by Mihael Isaev on 04.02.2020.
//

import Foundation

extension SwifQLable {
    public subscript (items items: SwifQLable...) -> SwifQLable {
        self.items(items)
    }
    
    public subscript (items items: [SwifQLable]) -> SwifQLable {
        self.items(items)
    }
    
    /// Represent provided values in round brackets separated with comma
    public func items(_ items: SwifQLable...) -> SwifQLable {
        self.items(items)
    }
    /// Represent values provided as array
    public func items(_ items: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        for (i, v) in items.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            for p in v.parts {
                switch p {
                case let p as SwifQLPartKeyPath:
                    parts.append(p.column)
                default:
                    parts.append(p)
                }
            }
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
