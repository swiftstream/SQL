//
//  TypeDDL.swift
//  SwifQL
//

import Foundation

extension SQLable {
    /// Appends the exact SQL operand `TYPE <type>`.
    public func type(_ type: Type) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .type, .space)
        parts.append(SQLPartType(type))
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Appends a parser-literal ENUM body. These labels are structural SQL
    /// literals and therefore never become ordinary prepared values.
    public func `enum`(_ values: String...) -> SQLable {
        `enum`(values)
    }

    /// Appends a parser-literal ENUM body from a caller-owned label list.
    public func `enum`(_ values: [String]) -> SQLable {
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
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Appends an ENUM body sourced by a child SELECT query. The child query
    /// keeps its own ordinary value binding mechanics.
    public func `enum`(select query: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .enum, .space, .openBracket)
        parts.append(contentsOf: query.parts)
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}