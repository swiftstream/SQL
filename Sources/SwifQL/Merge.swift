//
//  Merge.swift
//  SwifQL
//

import Foundation

extension SwifQLable {
    /// Starts a generic SQL-shaped `MERGE INTO` statement.
    ///
    /// A String target is represented as a table part, matching the existing
    /// INSERT INTO target behavior and keeping table names structural.
    public func merge(into target: SwifQLable) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("MERGE"), .space, .into, .space)
        if let name = target as? String {
            parts.append(SwifQLPartTable(name))
        } else {
            parts.append(contentsOf: target.parts)
        }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Builds `MERGE INTO ... USING ... ON ...` through the same incremental
    /// composition path as the individual helpers.
    public func merge(
        into target: SwifQLable,
        using source: SwifQLable,
        on condition: SwifQLable
    ) -> SwifQLable {
        merge(into: target).using(source).on(condition)
    }

    /// Appends DuckDB's structural `USING (<columns>)` shorthand.
    public func using(
        columns first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SwifQLable {
        using(columns: [first] + rest)
    }

    /// Appends DuckDB's structural `USING (<columns>)` shorthand.
    public func using(columns: [KeyPathLastPath]) -> SwifQLable {
        precondition(!columns.isEmpty, "MERGE USING requires at least one column")

        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .using, .space, .openBracket)
        for (index, column) in columns.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(SwifQLPartColumn(column.lastPath))
        }
        parts.append(o: .closeBracket)
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Appends the exact SQL branch action separator `THEN`.
    public var then: SwifQLable {
        appendingMergeClause([.then])
    }

    /// Appends DuckDB's bare `merge_action` returning expression.
    ///
    /// This intentionally renders an identifier, not `merge_action()`.
    public var mergeAction: SwifQLable {
        appendingMergeClause([.custom("merge_action")])
    }

    private func appendingMergeClause(
        _ clause: [SwifQLPartOperator]
    ) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        clause.forEach { parts.append($0) }
        return _SwifQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
