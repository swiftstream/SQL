import Foundation

/// A grouped column set in DuckDB's simplified UNPIVOT grammar.
///
/// The value keeps the grouped columns and optional alias as semantic state;
/// parentheses and `AS` are emitted only when the value is rendered.
public struct UnpivotColumnSet: SQLable {
    public let columns: [[SQLPart]]
    public let alias: String?

    public init(
        _ first: SQLable,
        _ rest: SQLable...,
        as alias: KeyPathLastPath? = nil
    ) {
        columns = ([first] + rest).map(\.parts)
        self.alias = alias?.lastPath
    }

    public var parts: [SQLPart] {
        var parts: [SQLPart] = [SQLPartOperator.openBracket]
        for (index, columnParts) in columns.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: columnParts)
        }
        parts.append(o: .closeBracket)

        if let alias {
            parts.append(o: .space, .as, .space)
            parts.append(SQLPartAlias(alias))
        }
        return parts
    }
}

extension SQLClauseOwner {
    /// The structural owner for DuckDB's simplified UNPIVOT grammar.
    public static let simplifiedUnpivot = Self(
        namespace: "swifql",
        name: "simplifiedUnpivot"
    )
}

extension SQLRenderScope {
    /// The bounded render scope used by DuckDB's simplified UNPIVOT ORDER BY.
    public static let simplifiedUnpivotOrderBy =
        SQLClauseOwner.simplifiedUnpivot.renderScope(for: .orderBy)
}

extension SQLable {
    /// Appends DuckDB's simplified UNPIVOT source clause and establishes its
    /// ownership of the output ORDER BY clause.
    public func unpivot(_ source: SQLable) -> SQLable {
        let fragment = SQLableParts(parts:
            [SQLPartOperator.space, .custom("UNPIVOT"), .space] + source.parts
        )
        return _SQLStructuralComposition.append(
            self,
            parts: fragment.parts,
            owners: [.orderBy: .simplifiedUnpivot]
        )
    }

    private func unpivotOnExpression(_ expression: SQLable) -> SQLable {
        guard let owner = structuralOwner(for: .on) else {
            return expression
        }
        return expression.scoped(owner.renderScope(for: .on))
    }

    /// Appends a comma-separated simplified-UNPIVOT ON list while preserving
    /// the current generic ON owner, if one is present.
    public func on(_ first: SQLable, _ rest: SQLable...) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.on,
            SQLPartOperator.space
        ]

        for (index, expression) in ([first] + rest).enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: unpivotOnExpression(expression).parts)
        }

        return structurallyAppending(SQLableParts(parts: parts))
    }

    /// Appends one structural `NAME` identifier and one structural `VALUE`
    /// identifier to simplified UNPIVOT.
    public func into(
        name nameColumn: KeyPathLastPath,
        value valueColumn: KeyPathLastPath
    ) -> SQLable {
        appendUnpivotInto(
            name: nameColumn,
            values: [valueColumn]
        )
    }

    /// Appends one structural `NAME` identifier and a non-empty structural
    /// `VALUE` identifier list to simplified UNPIVOT.
    public func into(
        name nameColumn: KeyPathLastPath,
        values first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        appendUnpivotInto(
            name: nameColumn,
            values: [first] + rest
        )
    }

    private func appendUnpivotInto(
        name nameColumn: KeyPathLastPath,
        values: [KeyPathLastPath]
    ) -> SQLable {
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.into,
            SQLPartOperator.space,
            SQLPartOperator.custom("NAME"),
            SQLPartOperator.space,
            SQLPartColumn(nameColumn.lastPath),
            SQLPartOperator.space,
            SQLPartOperator.custom("VALUE"),
            SQLPartOperator.space
        ]
        for (index, value) in values.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(SQLPartColumn(value.lastPath))
        }
        return structurallyAppending(SQLableParts(parts: parts))
    }
}