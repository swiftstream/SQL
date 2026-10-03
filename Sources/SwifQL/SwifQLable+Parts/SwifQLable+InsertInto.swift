//
//  SwifQLable+InsertInto.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

extension SwifQLable {
    public subscript (newColumns items: NewColumn...) -> SwifQLable {
        newColumns(items)
    }
    
    public subscript (newColumns items: [NewColumn]) -> SwifQLable {
        newColumns(items)
    }
    
    public func newColumns(_ items: NewColumn...) -> SwifQLable {
        newColumns(items)
    }
    
    public func newColumns(_ items: [NewColumn]) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        items.enumerated().forEach { i, v in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public subscript (fields items: SwifQLable...) -> SwifQLable {
        fields(items)
    }
    
    public subscript (fields items: [SwifQLable]) -> SwifQLable {
        fields(items)
    }
    
    /// Represent just a list of fields in round brackets separated by comma
    public func fields(_ items: SwifQLable...) -> SwifQLable {
        fields(items)
    }
    
    /// Represent just a list of fields in round brackets separated by comma
    public func fields(_ items: [SwifQLable]) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        items.compactMap { v -> SwifQLPart? in
            if let part = v.parts.first as? SwifQLKeyPathable, let lastPath = part.paths.last {
                return SwifQLPartColumn(lastPath)
            } else if let name = v as? String {
                return SwifQLPartColumn(name)
            }
            return nil
        }
        .enumerated()
        .forEach { i, v in
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(v)
        }
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public var insert: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .insert)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public var into: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .into)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public subscript (table item: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        if let name = item as? String {
            parts.append(SwifQLPartTable(name))
        } else {
            parts.append(contentsOf: item.parts)
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func insertInto(_ table: SwifQLable, fields: SwifQLable...) -> SwifQLable {
        insertInto(table, fields: fields)
    }
    public func insertInto(_ table: SwifQLable, fields: [SwifQLable]) -> SwifQLable {
        insert.into[table: table].fields(fields)
    }

    /// Appends `INSERT INTO` and a target table without synthesizing an empty
    /// field list.
    public func insertInto(_ table: SwifQLable) -> SwifQLable {
        insert.into[table: table]
    }

}
