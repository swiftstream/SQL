//
//  SQLable+Interval.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/08/2019.
//

import Foundation

//MARK: Interval

extension SQLable {
    public var interval: SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .interval)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
    public func interval(_ expression: String) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .interval)
        parts.append(o: .space)
        parts.append(o: .custom(expression.singleQuotted))
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
