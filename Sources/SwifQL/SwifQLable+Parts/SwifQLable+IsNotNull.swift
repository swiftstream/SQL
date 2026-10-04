//
//  SQLable+IsNotNull.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: IS NOT NULL

extension SQLable {
    public var isNotNull: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .isNotNull)
        parts.append(o: .space)
        return _SQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
