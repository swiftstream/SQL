//
//  SQLable+Any.swift
//
//
//  Created by Mihael Isaev on 26.10.2020.
//

import Foundation

//MARK: ANY

extension SQLable {
    public var any: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .any)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    public func any(_ subquery: SQLable) -> SQLable {
        var parts: [SQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .any)
        parts.append(o: .openBracket)
        parts.append(contentsOf: subquery.parts)
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
