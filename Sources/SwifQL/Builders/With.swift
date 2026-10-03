//
//  With.swift
//  SwifQL
//
//  Created by Taylor McIntyre on 2020-01-16.
//

import Foundation

//MARK: WITH

public class With: SwifQLable {
    public var parts: [SwifQLPart]
    
    public init(_ table: SwifQLable, columns: [SwifQLable] = [], _ query: SwifQLable) {
        parts = table.parts
        if !columns.isEmpty {
            parts.append(o: .space)
            parts.append(o: .openBracket)
            for (i, v) in columns.enumerated() {
                if i > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(contentsOf: v.parts)
            }
            parts.append(o: .closeBracket)
        }
        parts.append(o: .space)
        parts.append(o: .as)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        parts.append(contentsOf: _SwifQLStructuralComposition.withQueryPartsInsideParentheses(for: query))
        parts.append(o: .closeBracket)
    }
}
