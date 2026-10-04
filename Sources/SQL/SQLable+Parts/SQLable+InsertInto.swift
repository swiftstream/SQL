//
//  SQLable+InsertInto.swift
//  SQLCore
//
//  Created by Mihael Isaev on 13/11/2018.
//

import Foundation

extension SQLable {
    public subscript (newColumns items: NewColumn...) -> SQLable {
        newColumns(items)
    }
    
    public subscript (newColumns items: [NewColumn]) -> SQLable {
        newColumns(items)
    }
    
    public func newColumns(_ items: NewColumn...) -> SQLable {
        newColumns(items)
    }
    
    public func newColumns(_ items: [NewColumn]) -> SQLable {
        var parts: [SQLPart] = self.parts
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public subscript (fields items: SQLable...) -> SQLable {
        fields(items)
    }
    
    public subscript (fields items: [SQLable]) -> SQLable {
        fields(items)
    }
    
    /// Represent just a list of fields in round brackets separated by comma
    public func fields(_ items: SQLable...) -> SQLable {
        fields(items)
    }
    
    /// Represent just a list of fields in round brackets separated by comma
    public func fields(_ items: [SQLable]) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        items.compactMap { v -> SQLPart? in
            if let part = v.parts.first as? SQLKeyPathable, let lastPath = part.paths.last {
                return SQLPartColumn(lastPath)
            } else if let name = v as? String {
                return SQLPartColumn(name)
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public var insert: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .insert)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public var into: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .into)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public subscript (table item: SQLable) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        if let name = item as? String {
            parts.append(SQLPartTable(name))
        } else {
            parts.append(contentsOf: item.parts)
        }
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func insertInto(_ table: SQLable, fields: SQLable...) -> SQLable {
        insertInto(table, fields: fields)
    }
    public func insertInto(_ table: SQLable, fields: [SQLable]) -> SQLable {
        insert.into[table: table].fields(fields)
    }

    /// Appends `INSERT INTO` and a target table without synthesizing an empty
    /// field list.
    public func insertInto(_ table: SQLable) -> SQLable {
        insert.into[table: table]
    }

}
