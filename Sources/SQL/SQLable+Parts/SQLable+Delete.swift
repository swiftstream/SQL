//
//  SQLable+Delete.swift
//  SwifQL
//
//  Created by Mihael Isaev on 26/11/2018.
//

import Foundation

extension SQLable {
    public var delete: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .delete)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func delete(from table: SQLable) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .delete)
        parts.append(o: .space)
        parts.append(o: .from)
        parts.append(o: .space)
        parts.append(contentsOf: table.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
