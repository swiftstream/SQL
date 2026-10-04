//
//  SQLable+AddQuery.swift
//  SwifQL
//
//  Created by Mihael Isaev on 18.05.2020.
//

import Foundation

extension SQLable {
    func addQuery(_ q: SQLable) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(contentsOf: q.parts)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
