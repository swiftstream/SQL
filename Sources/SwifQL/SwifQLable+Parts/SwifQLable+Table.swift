//
//  SQLable+Table.swift
//  
//
//  Created by Mihael Isaev on 25.01.2020.
//

import Foundation

extension SQLable {
    public var table: SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .table)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func table(_ name: String) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .table)
        parts.append(o: .space)
        parts.append(SQLPartTable(name))
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
