//
//  SwifQLable+Epoch.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: Epoch

extension SwifQLable {
    public var epoch: SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .epoch)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
    
    public func epoch(with value: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom(Op.epoch._value.singleQuotted))
        parts.append(o: .space)
        parts.append(o: .custom("+"))
        parts.append(o: .space)
        parts.append(contentsOf: value.parts)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
