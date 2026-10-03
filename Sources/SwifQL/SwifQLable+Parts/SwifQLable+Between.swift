//
//  SwifQLable+Between.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: BETWEEN

extension SwifQLable {
    public func between(_ part: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .between)
        parts.append(o: .space)
        parts.append(contentsOf: part.parts)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
