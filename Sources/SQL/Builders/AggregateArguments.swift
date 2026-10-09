//
//  AggregateArguments.swift
//  SQL
//

import Foundation

public struct AggregateArguments {
    enum Payload {
        case empty
        case regular([[SQLPart]], orderBy: [[SQLPart]]?)
        case distinct(Distinct.AggregateMode, orderBy: [[SQLPart]]?)
    }

    let payload: Payload

    init(payload: Payload) {
        self.payload = payload
    }

    public static var empty: Self {
        .init(payload: .empty)
    }

    var aggregateBodyParts: [SQLPart] {
        switch payload {
        case .empty:
            return []

        case .regular(let arguments, let orderBy):
            return Self.render(arguments: arguments, distinct: false, orderBy: orderBy)

        case .distinct(let mode, let orderBy):
            switch mode {
            case .on:
                preconditionFailure("DISTINCT ON is not valid in aggregate argument ownership.")

            case .argumentList(let arguments):
                guard !arguments.isEmpty else {
                    preconditionFailure("DISTINCT aggregate argument list must not be empty.")
                }
                return Self.render(arguments: arguments, distinct: true, orderBy: orderBy)
            }
        }
    }

    private static func render(
        arguments: [[SQLPart]],
        distinct: Bool,
        orderBy: [[SQLPart]]?
    ) -> [SQLPart] {
        var parts: [SQLPart] = []

        if distinct {
            parts.append(SQLPartOperator.distinct)
            parts.append(SQLPartOperator.space)
        }

        for (index, argument) in arguments.enumerated() {
            if index > 0 {
                parts.append(SQLPartOperator.comma)
                parts.append(SQLPartOperator.space)
            }
            parts.append(contentsOf: argument)
        }

        if let orderBy, !orderBy.isEmpty {
            if !arguments.isEmpty {
                parts.append(SQLPartOperator.space)
            }
            parts.append(SQLPartOperator.order)
            parts.append(SQLPartOperator.space)
            parts.append(SQLPartOperator.by)
            parts.append(SQLPartOperator.space)

            for (index, item) in orderBy.enumerated() {
                if index > 0 {
                    parts.append(SQLPartOperator.comma)
                    parts.append(SQLPartOperator.space)
                }
                parts.append(contentsOf: item)
            }
        }

        return parts
    }
}

@resultBuilder
public enum AggregateArgumentBuilder {
    public struct Collecting {
        let arguments: [[SQLPart]]

        init(arguments: [[SQLPart]]) {
            self.arguments = arguments
        }
    }

    public struct DistinctPhase {
        let mode: Distinct.AggregateMode

        init(mode: Distinct.AggregateMode) {
            self.mode = mode
        }
    }

    public struct AfterBranch {
        let payload: AggregateArguments.Payload

        init(payload: AggregateArguments.Payload) {
            self.payload = payload
        }
    }

    public struct Ordered {
        let payload: AggregateArguments.Payload

        init(payload: AggregateArguments.Payload) {
            self.payload = payload
        }
    }

    public static func buildExpression(_ expression: any SQLable) -> Collecting {
        Collecting(arguments: [expression.parts])
    }

    public static func buildExpression(_ distinct: Distinct) -> DistinctPhase {
        DistinctPhase(mode: distinct._aggregateMode)
    }

    public static func buildExpression(_ orderBy: OrderByClause) -> OrderByClause {
        orderBy
    }

    public static func buildBlock() -> AggregateArguments {
        .empty
    }

    public static func buildPartialBlock(first: Collecting) -> Collecting {
        first
    }

    public static func buildPartialBlock(first: DistinctPhase) -> DistinctPhase {
        first
    }

    public static func buildPartialBlock(first: AfterBranch) -> AfterBranch {
        first
    }

    public static func buildPartialBlock(
        accumulated: Collecting,
        next: Collecting
    ) -> Collecting {
        Collecting(arguments: accumulated.arguments + next.arguments)
    }

    public static func buildPartialBlock(
        accumulated: Collecting,
        next: OrderByClause
    ) -> Ordered {
        Ordered(
            payload: .regular(
                accumulated.arguments,
                orderBy: orderParts(next)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: DistinctPhase,
        next: OrderByClause
    ) -> Ordered {
        Ordered(
            payload: .distinct(
                accumulated.mode,
                orderBy: orderParts(next)
            )
        )
    }

    public static func buildPartialBlock(
        accumulated: AfterBranch,
        next: OrderByClause
    ) -> Ordered {
        switch accumulated.payload {
        case .empty:
            return Ordered(payload: .regular([], orderBy: orderParts(next)))
        case .regular(let arguments, _):
            return Ordered(payload: .regular(arguments, orderBy: orderParts(next)))
        case .distinct(let mode, _):
            return Ordered(payload: .distinct(mode, orderBy: orderParts(next)))
        }
    }

    public static func buildEither(first component: Collecting) -> AfterBranch {
        AfterBranch(payload: .regular(component.arguments, orderBy: nil))
    }

    public static func buildEither(second component: Collecting) -> AfterBranch {
        AfterBranch(payload: .regular(component.arguments, orderBy: nil))
    }

    public static func buildEither(first component: DistinctPhase) -> AfterBranch {
        AfterBranch(payload: .distinct(component.mode, orderBy: nil))
    }

    public static func buildEither(second component: DistinctPhase) -> AfterBranch {
        AfterBranch(payload: .distinct(component.mode, orderBy: nil))
    }

    public static func buildOptional(_ component: Collecting?) -> Collecting {
        component ?? Collecting(arguments: [])
    }

    public static func buildOptional(_ component: DistinctPhase?) -> AfterBranch {
        guard let component else {
            return AfterBranch(payload: .regular([], orderBy: nil))
        }
        return AfterBranch(payload: .distinct(component.mode, orderBy: nil))
    }

    public static func buildArray(_ components: [Collecting]) -> Collecting {
        Collecting(arguments: components.flatMap(\.arguments))
    }

    public static func buildFinalResult(_ component: Collecting) -> AggregateArguments {
        AggregateArguments(payload: .regular(component.arguments, orderBy: nil))
    }

    public static func buildFinalResult(_ component: DistinctPhase) -> AggregateArguments {
        AggregateArguments(payload: .distinct(component.mode, orderBy: nil))
    }

    public static func buildFinalResult(_ component: AfterBranch) -> AggregateArguments {
        AggregateArguments(payload: component.payload)
    }

    public static func buildFinalResult(_ component: Ordered) -> AggregateArguments {
        AggregateArguments(payload: component.payload)
    }

    public static func buildFinalResult(_ component: AggregateArguments) -> AggregateArguments {
        component
    }

    private static func orderParts(_ orderBy: OrderByClause) -> [[SQLPart]] {
        orderBy.items.map(\.parts).filter { !$0.isEmpty }
    }
}

extension Fn {
    public static func aggregate(
        _ fn: Name,
        @AggregateArgumentBuilder _ body: () -> AggregateArguments
    ) -> SQLable {
        let arguments = body()
        return build(fn, body: arguments.aggregateBodyParts)
    }
}
