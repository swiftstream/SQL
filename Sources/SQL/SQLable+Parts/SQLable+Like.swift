//
//  SQLable+Like.swift
//  SQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: LIKE

extension SQLable {
    var ownsStarProjectionSemanticRole: Bool {
        let receiverParts: [SQLPart]
        if let frame = parts.first as? SQLStructuralFramePart {
            receiverParts = frame.children
        } else {
            receiverParts = parts
        }

        for part in receiverParts.reversed() {
            if let operation = part as? SQLPartOperator,
               operation._value == " " {
                continue
            }

            return (part as? SQLSemanticRoleCarryingPart)?.semanticRole == .starProjection
        }

        return false
    }

    func applyingPatternOperator(
        _ operation: SQLPartOperator,
        to pattern: SQLable
    ) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(operation)
        parts.append(o: .space)
        if ownsStarProjectionSemanticRole {
            parts.append(contentsOf: pattern.scoped(.starPattern).parts)
        } else {
            parts.append(contentsOf: pattern.parts)
        }
        return _SQLStructuralComposition.reconstructingWholeValueTransform(
            from: self,
            resultParts: parts
        )
    }

    /// Builds query with `LIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SQL.root.select
    ///     // ...
    ///     .where((\User.$name).like(name))
    /// ```
    /// - Parameter part: `SQLable` element
    ///
    public func like(_ part: SQLable) -> SQLable {
        applyingPatternOperator(.like, to: part)
    }
}
