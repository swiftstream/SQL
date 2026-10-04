//
//  SQLable+Join.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: JOIN

extension SQLable {
    /// Join tables
    ///
    /// Example usage:
    /// - join with subquery
    /// ```swift
    /// let u = TableAlias("u")
    /// let subquery = |SwifQL
    ///     .select(Fn.count(\User.$id) => "users",
    ///             \User.$groupID => "groupID")
    ///     .from(User.table)
    ///     .groupBy(\User.$groupID)| => u
    /// let query = SQL.root.select(..., u.users)
    ///     .from(...)
    ///     .join(.left, subquery, on: u.groupID == \Group.$id)
    ///     .groupBy(..., u.users)
    /// ```
    ///
    /// - Parameters:
    ///   - mode: type of JOIN `JoinMode`
    ///   - expression: `Table` or `subquery`
    ///   - predicates: which columns should be used to make `JOIN`
    /// - Returns: `SQLable`
    public func join(_ mode: JoinMode = .none, _ expression: SQLable, on predicates: SQLable? = nil) -> SQLable {
        let join = SQLJoinBuilder(mode, expression, on: predicates)
        return structurallyAppending(SQLableParts(parts: [SQLPartOperator.space] + join.parts))
    }

    /// Join with an explicit SQL MATCH_CONDITION role followed by an
    /// optional ordinary ON equality condition. Existing on: joins remain
    /// ordinary ON clauses and are never remapped by dialect.
    public func join(
        _ mode: JoinMode? = nil,
        _ expression: SQLable,
        matchCondition: SQLable,
        on predicates: SQLable? = nil
    ) -> SQLable {
        let join = SQLJoinBuilder(
            mode,
            expression,
            matchCondition: matchCondition,
            on: predicates
        )
        return structurallyAppending(SQLableParts(parts: [SQLPartOperator.space] + join.parts))
    }

    /// Join with an explicit SQL MATCH_CONDITION role followed by structural
    /// USING equality/grouping names.
    public func join(
        _ mode: JoinMode,
        _ expression: SQLable,
        matchCondition: SQLable,
        using first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        makeMatchConditionUsingJoin(
            mode,
            expression,
            matchCondition: matchCondition,
            columns: [first] + rest
        )
    }

    /// Default-mode overload for explicit MATCH_CONDITION plus USING.
    public func join(
        _ expression: SQLable,
        matchCondition: SQLable,
        using first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        makeMatchConditionUsingJoin(
            .none,
            expression,
            matchCondition: matchCondition,
            columns: [first] + rest
        )
    }

    /// Array form for helper-driven explicit MATCH_CONDITION composition.
    public func join(
        _ mode: JoinMode,
        _ expression: SQLable,
        matchCondition: SQLable,
        using columns: [KeyPathLastPath]
    ) -> SQLable {
        makeMatchConditionUsingJoin(
            mode,
            expression,
            matchCondition: matchCondition,
            columns: columns
        )
    }

    /// Default-mode array form for explicit MATCH_CONDITION composition.
    public func join(
        _ expression: SQLable,
        matchCondition: SQLable,
        using columns: [KeyPathLastPath]
    ) -> SQLable {
        makeMatchConditionUsingJoin(
            .none,
            expression,
            matchCondition: matchCondition,
            columns: columns
        )
    }

    /// Join tables using structural column names from the last path segment.
    public func join(
        _ expression: SQLable,
        using first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        makeUsingJoin(.none, expression, columns: [first] + rest)
    }

    /// Join tables using structural column names from the last path segment.
    public func join(
        _ mode: JoinMode,
        _ expression: SQLable,
        using first: KeyPathLastPath,
        _ rest: KeyPathLastPath...
    ) -> SQLable {
        makeUsingJoin(mode, expression, columns: [first] + rest)
    }

    /// Array form for helper-driven composition. The SQL grammar requires at
    /// least one USING identifier.
    public func join(
        _ expression: SQLable,
        using columns: [KeyPathLastPath]
    ) -> SQLable {
        makeUsingJoin(.none, expression, columns: columns)
    }

    /// Array form for helper-driven composition. The SQL grammar requires at
    /// least one USING identifier.
    public func join(
        _ mode: JoinMode,
        _ expression: SQLable,
        using columns: [KeyPathLastPath]
    ) -> SQLable {
        makeUsingJoin(mode, expression, columns: columns)
    }

    private func makeUsingJoin(
        _ mode: JoinMode,
        _ expression: SQLable,
        columns: [KeyPathLastPath]
    ) -> SQLable {
        precondition(!columns.isEmpty, "JOIN USING requires at least one column")

        let join = SQLJoinBuilder(mode, expression, using: columns)
        return structurallyAppending(SQLableParts(parts: [SQLPartOperator.space] + join.parts))
    }

    private func makeMatchConditionUsingJoin(
        _ mode: JoinMode,
        _ expression: SQLable,
        matchCondition: SQLable,
        columns: [KeyPathLastPath]
    ) -> SQLable {
        precondition(!columns.isEmpty, "JOIN MATCH_CONDITION USING requires at least one column")

        let join = SQLJoinBuilder(
            mode,
            expression,
            matchCondition: matchCondition,
            using: columns
        )
        return structurallyAppending(SQLableParts(parts: [SQLPartOperator.space] + join.parts))
    }

}
