//
//  SQLable+Slice.swift
//  SQL
//

import Foundation

/// Structural SQL slice operand used inside the existing SQLable subscript.
///
/// The value owns only the bracket interior. Square-bracket ownership and
/// expression-base grouping remain with SQLable's existing subscript.
public struct slice: SQLable {
    private let lowerParts: [SQLPart]?
    private let upperParts: [SQLPart]?
    private let stepParts: [SQLPart]?

    public init(_ lower: any SQLable, _ upper: any SQLable) {
        self.lowerParts = lower.parts
        self.upperParts = upper.parts
        self.stepParts = nil
    }

    public init(through upper: any SQLable) {
        self.lowerParts = nil
        self.upperParts = upper.parts
        self.stepParts = nil
    }

    public init(from lower: any SQLable) {
        self.lowerParts = lower.parts
        self.upperParts = nil
        self.stepParts = nil
    }

    public init() {
        self.lowerParts = nil
        self.upperParts = nil
        self.stepParts = nil
    }

    public init(
        _ lower: any SQLable,
        _ upper: any SQLable,
        step: any SQLable
    ) {
        self.lowerParts = lower.parts
        self.upperParts = upper.parts
        self.stepParts = step.parts
    }

    public var parts: [SQLPart] {
        var parts: [SQLPart] = []

        if let lowerParts {
            parts.append(contentsOf: lowerParts)
        }

        parts.append(SQLPartOperator(":"))

        if let upperParts {
            parts.append(contentsOf: upperParts)
        }

        if let stepParts {
            parts.append(SQLPartOperator(":"))
            parts.append(contentsOf: stepParts)
        }

        return parts
    }
}
