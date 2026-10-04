//
//  SQLable+Not.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: NOT

extension SQLable {
    public var not: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .not)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    public func not(_ part: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .not)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
