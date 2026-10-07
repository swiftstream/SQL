//
//  SQLable+Subscript.swift
//  SwifQL
//
//  Created by Mihael Isaev on 20/03/2019.
//

import Foundation

/// Preserves the two operands of a postfix subscript until dialect rendering.
/// Ordinary SQL expression grouping is not a structural SQL-region frame.
struct SQLExpressionSubscriptPart: SQLPart {
    let baseParts: [SQLPart]
    let itemParts: [SQLPart]
}

extension SQLable  {
    /// Gives ability to append something wrapped into square brackets
    /// # Example
    /// ```swift
    /// Fn.array_agg(Fn.to_jsonb("Attachment"))[1]
    /// ```
    /// # PostgreSQL representation
    /// ```sql
    /// (array_agg(to_jsonb("Attachment")))[1]
    /// ```
    public subscript (_ items: SQLable) -> SQLable {
        let baseParts = self.parts
        let itemParts = items.parts

        // DESIGN-037: a statement/set-result root is not an ordinary array
        // expression. Retain its established whole-value suffix composition.
        if _SQLStructuralComposition.rootFrame(in: baseParts) != nil {
            var parts = baseParts
            parts.append(o: .openSquareBracket)
            parts.append(contentsOf: itemParts)
            parts.append(o: .closeSquareBracket)
            return _SQLStructuralComposition.reconstructingWholeValueTransform(
                from: SQLableParts(rawParts: baseParts),
                resultParts: parts
            )
        }

        return SQLableParts(parts: SQLExpressionSubscriptPart(
            baseParts: baseParts,
            itemParts: itemParts
        ))
    }
}
