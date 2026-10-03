//
//  DML.swift
//  SwifQL
//

import Foundation

extension SwifQLable {
    /// Builds the exact SQL statement `TRUNCATE <table>`.
    public func truncate(_ table: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("TRUNCATE"), .space)
        if let name = table as? String {
            parts.append(SwifQLPartTable(name))
        } else {
            parts.append(contentsOf: table.parts)
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
