//
//  SQLable+PartitionBy.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

import Foundation

//MARK: Partition By

extension SQLable {
    public var partition: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .partition)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public var by: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .by)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public func partition(by expression: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .partition)
        parts.append(o: .space)
        parts.append(o: .by)
        parts.append(o: .space)
        parts.append(contentsOf: expression.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
