//
//  SwifQLable+Type.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SwifQLable {
    public var type: SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .type)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func type(_ name: String) -> SwifQLable {
        type(nil, name)
    }
    
    public func type(_ schema: String?, _ name: String) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .type)
        if let schema = schema {
            parts.append(o: .space)
            parts.append(contentsOf: Path.Schema(schema).table(name).parts)
        } else {
            parts.append(o: .space)
            parts.append(contentsOf: Path.Table(name).parts)
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
