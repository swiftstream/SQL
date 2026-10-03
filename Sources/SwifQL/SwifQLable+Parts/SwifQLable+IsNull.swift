//
//  SwifQLable+IsNull.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: IS NULL

extension SwifQLable {
    public var isNull: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .isNull)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
