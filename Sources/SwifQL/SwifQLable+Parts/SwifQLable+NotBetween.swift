//
//  SwifQLable+NotBetween.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: NOT BETWEEN

extension SwifQLable {
    public func notBetween(_ part: SwifQLable) -> SwifQLable {
        let transform: [SwifQLPart] = [
            SwifQLPartOperator.space,
            .not,
            .space,
            .between,
            .space
        ] + part.parts
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(
            from: self,
            resultParts: self.parts + transform
        )
    }
}
