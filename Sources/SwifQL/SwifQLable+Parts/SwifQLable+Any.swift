//
//  SwifQLable+Any.swift
//
//
//  Created by Mihael Isaev on 26.10.2020.
//

import Foundation

//MARK: ANY

extension SwifQLable {
    public var any: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .any)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    public func any(_ subquery: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .any)
        parts.append(o: .openBracket)
        parts.append(contentsOf: subquery.parts)
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
