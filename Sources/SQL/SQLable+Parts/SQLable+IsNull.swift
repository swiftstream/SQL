//
//  SQLable+IsNull.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: IS NULL

extension SQLable {
    public var isNull: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .isNull)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
