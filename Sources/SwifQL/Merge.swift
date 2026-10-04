//
//  Merge.swift
//  SwifQL
//

import Foundation

extension SQLable {
    /// Starts a generic SQL-shaped `MERGE INTO` statement.
    ///
    /// A String target is represented as a table part, matching the existing
    /// INSERT INTO target behavior and keeping table names structural.
    public func merge(into target: SQLable) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .custom("MERGE"), .space, .into, .space)
        if let name = target as? String {
            parts.append(SQLPartTable(name))
        } else {
            parts.append(contentsOf: target.parts)
        }
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Builds `MERGE INTO ... USING ... ON ...` through the same incremental
    /// composition path as the individual helpers.
    public func merge(
        into target: SQLable,
        using source: SQLable,
        on condition: SQLable
    ) -> SQLable {
        merge(into: target).using(source).on(condition)
    }

    /// Appends DuckDB's structural `USING (<columns>)` shorthand.
    public func using(
        columns first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        using(columns: [first] + rest)
    }

    /// Appends DuckDB's structural `USING (<columns>)` shorthand.
    public func using(columns: [KeyPathLastPath]) -> SQLable {
        precondition(!columns.isEmpty, "MERGE USING requires at least one column")

        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .using, .space, .openBracket)
        for (index, column) in columns.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(SQLPartColumn(column.lastPath))
        }
        parts.append(o: .closeBracket)
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }

    /// Appends the exact SQL branch action separator `THEN`.
    public var then: SQLable {
        appendingMergeClause([.then])
    }

    /// Appends DuckDB's bare `merge_action` returning expression.
    ///
    /// This intentionally renders an identifier, not `merge_action()`.
    public var mergeAction: SQLable {
        appendingMergeClause([.custom("merge_action")])
    }

    private func appendingMergeClause(
        _ clause: [SQLPartOperator]
    ) -> SQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        clause.forEach { parts.append($0) }
        return _SQLStructuralComposition.reconstructingSequentialContinuation(from: self, resultParts: parts)
    }
}
