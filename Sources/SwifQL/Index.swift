//
//  Index.swift
//  SwifQL
//

import Foundation

extension SQLable {
    /// Appends one direct parenthesized list of index item parts.
    public func indexItems(_ items: IndexItem...) -> SQLable {
        indexItems(items)
    }

    /// Appends one direct parenthesized list of index item parts.
    public func indexItems(_ items: [IndexItem]) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        for (index, item) in items.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: item.parts)
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
