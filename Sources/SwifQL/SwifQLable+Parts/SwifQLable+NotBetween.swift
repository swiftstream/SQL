//
//  SQLable+NotBetween.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: NOT BETWEEN

extension SQLable {
    public func notBetween(_ part: SQLable) -> SQLable {
        let transform: [SQLPart] = [
            SQLPartOperator.space,
            .not,
            .space,
            .between,
            .space
        ] + part.parts
        return _SQLStructuralComposition.reconstructingWholeValueTransform(
            from: self,
            resultParts: self.parts + transform
        )
    }
}
