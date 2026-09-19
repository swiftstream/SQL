//
//  TypeDDL.swift
//  SwifQL
//

import Foundation

extension SwifQLable {
    /// Appends the exact SQL operand `TYPE <type>`.
    public func type(_ type: SwifQL.`Type`) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .type, .space)
        parts.append(SwifQLPartType(type))
        return SwifQLableParts(parts: parts)
    }

    /// Appends a parser-literal ENUM body. These labels are structural SQL
    /// literals and therefore never become ordinary prepared values.
    public func `enum`(_ values: String...) -> SwifQLable {
        `enum`(values)
    }

    /// Appends a parser-literal ENUM body from a caller-owned label list.
    public func `enum`(_ values: [String]) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .enum, .space, .openBracket)
        for (index, value) in values.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(safe: value)
        }
        parts.append(o: .closeBracket)
        return SwifQLableParts(parts: parts)
    }

    /// Appends an ENUM body sourced by a child SELECT query. The child query
    /// keeps its own ordinary value binding mechanics.
    public func `enum`(select query: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .enum, .space, .openBracket)
        parts.append(contentsOf: query.parts)
        parts.append(o: .closeBracket)
        return SwifQLableParts(parts: parts)
    }
}
