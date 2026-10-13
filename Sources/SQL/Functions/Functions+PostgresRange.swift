//
//  Functions+PostgresRange.swift
//  SQL
//

extension Fn.Name {
    public static let isEmpty: Self = .init("isempty")
    public static let lowerInc: Self = .init("lower_inc")
    public static let upperInc: Self = .init("upper_inc")
    public static let lowerInf: Self = .init("lower_inf")
    public static let upperInf: Self = .init("upper_inf")
    public static let rangeMerge: Self = .init("range_merge")
    public static let multiRange: Self = .init("multirange")
    public static let unNest: Self = .init("unnest")
    public static let rangeAgg: Self = .init("range_agg")
    public static let rangeIntersectAgg: Self = .init("range_intersect_agg")
}

extension Fn {
    public static func isEmpty(_ value: SQLable) -> SQLable {
        build(.isEmpty, body: value.parts)
    }

    public static func lowerInc(_ value: SQLable) -> SQLable {
        build(.lowerInc, body: value.parts)
    }

    public static func upperInc(_ value: SQLable) -> SQLable {
        build(.upperInc, body: value.parts)
    }

    public static func lowerInf(_ value: SQLable) -> SQLable {
        build(.lowerInf, body: value.parts)
    }

    public static func upperInf(_ value: SQLable) -> SQLable {
        build(.upperInf, body: value.parts)
    }

    public static func rangeMerge(_ lhs: SQLable, _ rhs: SQLable) -> SQLable {
        var parts = lhs.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: rhs.parts)
        return build(.rangeMerge, body: parts)
    }

    public static func rangeMerge(_ multirange: SQLable) -> SQLable {
        build(.rangeMerge, body: multirange.parts)
    }

    public static func multiRange(_ range: SQLable) -> SQLable {
        build(.multiRange, body: range.parts)
    }

    public static func unNest(_ multirange: SQLable) -> SQLable {
        build(.unNest, body: multirange.parts)
    }

    public static func rangeAgg(_ aggregateExpression: SQLable) -> SQLable {
        build(.rangeAgg, body: aggregateExpression.parts)
    }

    public static func rangeAgg(
        @AggregateArgumentBuilder _ body: () -> AggregateArguments
    ) -> SQLable {
        aggregate(.rangeAgg, body)
    }

    public static func rangeIntersectAgg(_ aggregateExpression: SQLable) -> SQLable {
        build(.rangeIntersectAgg, body: aggregateExpression.parts)
    }

    public static func rangeIntersectAgg(
        @AggregateArgumentBuilder _ body: () -> AggregateArguments
    ) -> SQLable {
        aggregate(.rangeIntersectAgg, body)
    }
}
