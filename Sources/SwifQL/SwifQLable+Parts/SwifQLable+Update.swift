//
//  SQLable+Update.swift
//  SwifQL
//
//  Created by Mihael Isaev on 26/11/2018.
//

import Foundation

//MARK: UPDATE

extension SQLable {
    public var update: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .update)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func update(_ tables: SQLable...) -> SQLable {
        update(tables)
    }
    
    public func update(_ tables: [SQLable]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .update)
        parts.append(o: .space)
        for (i, v) in tables.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
