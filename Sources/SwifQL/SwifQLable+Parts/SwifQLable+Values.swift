//
//  SQLable+Values.swift
//  App
//
//  Created by Mihael Isaev on 25/11/2018.
//

import Foundation

extension SQLable {
    public subscript (values items: SQLable...) -> SQLable {
        values(items)
    }
    
    public subscript (values items: [SQLable]) -> SQLable {
        values(items)
    }
    
    /// Represent just `VALUES` keyword
    public var values: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .values)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    /// Represent provided values in round brackets separated with comma
    public func values(_ items: SQLable...) -> SQLable {
        values(items)
    }
    /// Represent provided values in round brackets separated with comma
    public func values(_ items: [SQLable]) -> SQLable {
        var parts: [SQLPart] = self.parts
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    /// e.g. INSERT INTO CarBrands (name) VALUES ("Acura"), ("Audi"), ("BMW")
    public func values(array: [SQLable]...) -> SQLable {
        values(array: array)
    }
    /// e.g. INSERT INTO CarBrands (name) VALUES ("Acura"), ("Audi"), ("BMW")
    public func values(array: [[SQLable]]) -> SQLable {
        var parts: [SQLPart] = self.parts
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
