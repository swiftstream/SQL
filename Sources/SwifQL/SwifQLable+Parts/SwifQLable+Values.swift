//
//  SwifQLable+Values.swift
//  App
//
//  Created by Mihael Isaev on 25/11/2018.
//

import Foundation

extension SwifQLable {
    public subscript (values items: SwifQLable...) -> SwifQLable {
        values(items)
    }
    
    public subscript (values items: [SwifQLable]) -> SwifQLable {
        values(items)
    }
    
    /// Represent just `VALUES` keyword
    public var values: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .values)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    /// Represent provided values in round brackets separated with comma
    public func values(_ items: SwifQLable...) -> SwifQLable {
        values(items)
    }
    /// Represent provided values in round brackets separated with comma
    public func values(_ items: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        for (i, v) in items.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    /// e.g. INSERT INTO CarBrands (name) VALUES ("Acura"), ("Audi"), ("BMW")
    public func values(array: [SwifQLable]...) -> SwifQLable {
        values(array: array)
    }
    /// e.g. INSERT INTO CarBrands (name) VALUES ("Acura"), ("Audi"), ("BMW")
    public func values(array: [[SwifQLable]]) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        for (i, v) in array.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(o: .openBracket)
            for (i, v) in v.enumerated() {
                if i > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(contentsOf: v.parts)
            }
            parts.append(o: .closeBracket)
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
