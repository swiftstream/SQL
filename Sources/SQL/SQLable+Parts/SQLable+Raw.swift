//
//  SQLable+Raw.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: Ability to append anything to query as a raw string

extension SQLable {
    public func raw(_ anything: String) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom(anything))
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    
    public static func raw(_ anything: String) -> SQLable {
        var parts: [SQLPart] = []
        parts.append(o: .space)
        parts.append(o: .custom(anything))
        return SQLableParts(parts: parts)
    }
}

extension String {
    public var raw: SQLable {
        SQL.root.raw(self)
    }
}