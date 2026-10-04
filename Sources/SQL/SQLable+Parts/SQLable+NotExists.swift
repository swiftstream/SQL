//
//  SQLable+NotExists.swift
//  SwifQL
//
//  Created by Mihael Isaev on 23/07/2019.
//

import Foundation

//MARK: Exists

extension SQLable {
    public func notExists(_ predicates: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .not)
        parts.append(o: .space)
        parts.append(o: .exists)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(contentsOf: predicates.parts)
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
