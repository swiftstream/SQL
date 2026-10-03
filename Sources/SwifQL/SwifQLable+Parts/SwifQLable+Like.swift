//
//  SwifQLable+Like.swift
//  SwifQLCore
//
//  Created by Mihael Isaev on 16/11/2018.
//

import Foundation

//MARK: LIKE

extension SwifQLable {
    var ownsStarProjectionSemanticRole: Bool {
        let receiverParts: [SwifQLPart]
        if let frame = parts.first as? SwifQLStructuralFramePart {
            receiverParts = frame.children
        } else {
            receiverParts = parts
        }

        for part in receiverParts.reversed() {
            if let operation = part as? SwifQLPartOperator,
               operation._value == " " {
                continue
            }

            return (part as? SwifQLSemanticRoleCarryingPart)?.semanticRole == .starProjection
        }

        return false
    }

    func applyingPatternOperator(
        _ operation: SwifQLPartOperator,
        to pattern: SwifQLable
    ) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(operation)
        parts.append(o: .space)
        if ownsStarProjectionSemanticRole {
            parts.append(contentsOf: pattern.scoped(.starPattern).parts)
        } else {
            parts.append(contentsOf: pattern.parts)
        }
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(
            from: self,
            resultParts: parts
        )
    }

    /// Builds query with `LIKE` parameter
    ///
    /// Example usage:
    /// ```swift
    /// let name = "John"
    /// SwifQL.select
    ///     // ...
    ///     .where((\User.$name).like(name))
    /// ```
    /// - Parameter part: `SwifQLable` element
    ///
    public func like(_ part: SwifQLable) -> SwifQLable {
        applyingPatternOperator(.like, to: part)
    }
}
