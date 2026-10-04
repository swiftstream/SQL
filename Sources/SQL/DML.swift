//
//  DML.swift
//  SwifQL
//

import Foundation

extension SQLable {
    /// Builds the exact SQL statement `TRUNCATE <table>`.
    public func truncate(_ table: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("TRUNCATE"), .space)
        if let name = table as? String {
            parts.append(SQLPartTable(name))
        } else {
            parts.append(contentsOf: table.parts)
        }
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
