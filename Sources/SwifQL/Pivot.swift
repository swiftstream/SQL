import Foundation

extension SQLClauseOwner {
    /// The structural owner for DuckDB's simplified PIVOT grammar.
    public static let simplifiedPivot = Self(
        namespace: "swifql",
        name: "simplifiedPivot"
    )
}

extension SQLRenderScope {
    /// The bounded render scopes used by DuckDB's simplified PIVOT grammar.
    public static let simplifiedPivotOn =
        SQLClauseOwner.simplifiedPivot.renderScope(for: .on)

    public static let simplifiedPivotUsing =
        SQLClauseOwner.simplifiedPivot.renderScope(for: .using)

    /// Owner-derived scopes intentionally share the generic owner identity
    /// derivation used by GROUP BY and ORDER BY rendering.
    public static let simplifiedPivotGroupBy =
        SQLClauseOwner.simplifiedPivot.renderScope(for: .groupBy)

    public static let simplifiedPivotOrderBy =
        SQLClauseOwner.simplifiedPivot.renderScope(for: .orderBy)
}

extension SQLable {
    /// Appends DuckDB's simplified PIVOT source clause and establishes its
    /// ownership of its contextual ON, USING, GROUP BY, and ORDER BY clauses.
    public func pivot(_ source: SQLable) -> SQLable {
        let fragment = SQLableParts(parts:
            [SQLPartOperator.space, .custom("PIVOT"), .space] + source.parts
        )
        return _SQLStructuralComposition.append(
            self,
            parts: fragment.parts,
            owners: [
                .on: .simplifiedPivot,
                .using: .simplifiedPivot,
                .groupBy: .simplifiedPivot,
                .orderBy: .simplifiedPivot
            ]
        )
    }

    private func expression(
        _ expression: SQLable,
        scopedFor kind: SQLClauseKind
    ) -> SQLable {
        guard let owner = structuralOwner(for: kind) else {
            return expression
        }
        return expression.scoped(owner.renderScope(for: kind))
    }

    /// Appends SQL ON and applies context selected by the current root owner.
    public func on(_ expression: SQLable) -> SQLable {
        let scopedExpression = self.expression(expression, scopedFor: .on)
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.on,
            SQLPartOperator.space
        ]
        parts.append(contentsOf: scopedExpression.parts)
        return structurallyAppending(SQLableParts(parts: parts))
    }

    /// Appends simplified-PIVOT ON with a non-empty explicit IN list.
    public func on(
        _ expression: SQLable,
        in first: SQLable,
        _ rest: SQLable...
    ) -> SQLable {
        let scopedExpression = self.expression(expression, scopedFor: .on)
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.on,
            SQLPartOperator.space
        ]
        parts.append(contentsOf: scopedExpression.parts)
        parts.append(contentsOf: [
            SQLPartOperator.space,
            SQLPartOperator.in,
            SQLPartOperator.space,
            SQLPartOperator.openBracket
        ] as [SQLPart])

        for (index, value) in ([first] + rest).enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: value.parts)
        }
        parts.append(o: .closeBracket)

        return structurallyAppending(SQLableParts(parts: parts))
    }

    /// Appends SQL USING and applies context selected by the current root owner.
    public func using(_ expression: SQLable) -> SQLable {
        let scopedExpression = self.expression(expression, scopedFor: .using)
        var parts: [SQLPart] = [
            SQLPartOperator.space,
            SQLPartOperator.using,
            SQLPartOperator.space
        ]
        parts.append(contentsOf: scopedExpression.parts)
        return structurallyAppending(SQLableParts(parts: parts))
    }
}
