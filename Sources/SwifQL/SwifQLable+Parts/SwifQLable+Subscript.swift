//
//  SwifQLable+Subscript.swift
//  SwifQL
//
//  Created by Mihael Isaev on 20/03/2019.
//

import Foundation

extension SwifQLable  {
    /// Gives ability to append something wrapped into square brackets
    /// # Example
    /// ```swift
    /// Fn.array_agg(Fn.to_jsonb("Attachment"))[1]
    /// ```
    /// # SQL representation
    /// ```
    /// array_agg(to_jsonb("Attachment"))[1]
    /// ```
    public subscript (_ items: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.append(o: .openSquareBracket)
        parts.append(contentsOf: items.parts)
        parts.append(o: .closeSquareBracket)
        return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: self, resultParts: parts)
    }
}
