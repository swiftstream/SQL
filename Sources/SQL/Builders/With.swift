//
//  With.swift
//  SwifQL
//
//  Created by Taylor McIntyre on 2020-01-16.
//

import Foundation

//MARK: WITH

public class With: SQLable {
    public var parts: [SQLPart]
    
    public init(_ table: SQLable, columns: [SQLable] = [], _ query: SQLable) {
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
        parts.append(contentsOf: _SQLStructuralComposition.withQueryPartsInsideParentheses(for: query))
        parts.append(o: .closeBracket)
    }
}
