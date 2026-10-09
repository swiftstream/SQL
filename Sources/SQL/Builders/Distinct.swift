//
//  Distinct.swift
//  SwifQL
//
//  Created by Mihael Isaev on 02/03/2019.
//

import Foundation

//MARK: DISTINCT

public class Distinct: SQLable {
    enum AggregateMode {
        case argumentList([[SQLPart]])
        case on
    }

    public var parts: [SQLPart]

    /// Narrow internal metadata for declarative SELECT modifier ownership.
    ///
    /// `true` when this instance already carries one or more output projections
    /// (historical `Distinct(field...)` or `andAlso(nonEmptyFields)`). Not a
    /// public API. Never inferred from rendered SQL/token history.
    internal var _declarativeCarriesProjection: Bool

    /// Narrow aggregate-argument semantic identity.
    ///
    /// This preserves the released one-nominal Distinct API while allowing
    /// aggregate construction to reject DISTINCT ON without token inspection.
    internal var _aggregateMode: AggregateMode

    public convenience init (_ field: SQLable...) {
        self.init(field)
    }

    public init (_ fields: [SQLable]) {
        let snapshots = fields.map { $0.parts }

        parts = []
        _declarativeCarriesProjection = !snapshots.isEmpty
        _aggregateMode = .argumentList(snapshots)

        parts.append(o: .distinct)
        parts.append(o: .space)
        for (index, snapshot) in snapshots.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: snapshot)
        }
    }

    public convenience init (on field: SQLable...) {
        self.init(on: field)
    }

    public init (on fields: [SQLable]) {
        let snapshots = fields.map { $0.parts }

        parts = []
        _declarativeCarriesProjection = false
        _aggregateMode = .on

        parts.append(o: .distinct)
        parts.append(o: .space)
        parts.append(o: .on)
        parts.append(o: .space)
        parts.append(o: .openBracket)
        for (index, snapshot) in snapshots.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: snapshot)
        }
        parts.append(o: .closeBracket)
    }

    public convenience init(
        @DistinctArgumentBuilder _ body: () -> [SQLableParts]
    ) {
        self.init(body().map { $0 as SQLable })
    }

    public func andAlso(_ fields: SQLable...) -> Distinct {
        andAlso(fields)
    }

    public func andAlso(_ fields: [SQLable]) -> Distinct {
        let snapshots = fields.map { $0.parts }

        if !snapshots.isEmpty {
            _declarativeCarriesProjection = true
        }

        if case .argumentList(let current) = _aggregateMode {
            _aggregateMode = .argumentList(current + snapshots)
        }

        parts.append(o: .space)
        for (index, snapshot) in snapshots.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: snapshot)
        }
        return self
    }
}

@resultBuilder
public enum DistinctArgumentBuilder {
    public static func buildExpression(
        _ expression: any SQLable
    ) -> [SQLableParts] {
        [SQLableParts(rawParts: expression.parts)]
    }

    public static func buildExpression(
        _ orderBy: OrderByClause
    ) -> OrderByClause {
        orderBy
    }

    public static func buildBlock(
        _ components: [SQLableParts]...
    ) -> [SQLableParts] {
        components.flatMap { $0 }
    }

    public static func buildOptional(
        _ component: [SQLableParts]?
    ) -> [SQLableParts] {
        component ?? []
    }

    public static func buildEither(
        first component: [SQLableParts]
    ) -> [SQLableParts] {
        component
    }

    public static func buildEither(
        second component: [SQLableParts]
    ) -> [SQLableParts] {
        component
    }

    public static func buildArray(
        _ components: [[SQLableParts]]
    ) -> [SQLableParts] {
        components.flatMap { $0 }
    }
}
