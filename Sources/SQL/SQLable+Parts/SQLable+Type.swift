//
//  SQLable+Type.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SQLable {
    public var type: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .type)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func type(_ name: String) -> SQLable {
        type(nil, name)
    }
    
    public func type(_ schema: String?, _ name: String) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .type)
        if let schema = schema {
            parts.append(o: .space)
            parts.append(contentsOf: Path.Schema(schema).table(name).parts)
        } else {
            parts.append(o: .space)
            parts.append(contentsOf: Path.Table(name).parts)
        }
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
