//
//  Functions+Array.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let arrayAgg: Self = .init("array_agg")
    @available(*, deprecated, renamed: "arrayAgg")
    public static var array_agg: Self { .arrayAgg }
    public static let arrayRemove: Self = .init("array_remove")
    @available(*, deprecated, renamed: "arrayRemove")
    public static var array_remove: Self { .arrayRemove }
}

extension Fn {
    ///
    public static func arrayAgg(_ aggregateExpression: SQLable) -> SQLable {
        build(.arrayAgg, body: aggregateExpression.parts)
    }

    @available(*, deprecated, renamed: "arrayAgg(_:)")
    public static func array_agg(_ aggregateExpression: SQLable) -> SQLable {
        arrayAgg(aggregateExpression)
    }
    
    /// `SELECT array_remove(ARRAY[1,2,3,2], 2);` will return {1,3}
    public static func arrayRemove(_ queryPart: SQLable...) -> SQLable {
        arrayRemove(queryPart)
    }

    @available(*, deprecated, renamed: "arrayRemove(_:)")
    public static func array_remove(_ queryPart: SQLable...) -> SQLable {
        arrayRemove(queryPart)
    }
    
    /// `SELECT array_remove(ARRAY[1,2,3,2], 2);` will return {1,3}
    public static func arrayRemove(_ queryParts: [SQLable]) -> SQLable {
        var parts: [SQLPart] = []
        for (i, q) in queryParts.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: q.parts)
        }
        return build(.arrayRemove, body: parts)
    }

    @available(*, deprecated, renamed: "arrayRemove(_:)")
    public static func array_remove(_ queryParts: [SQLable]) -> SQLable {
        arrayRemove(queryParts)
    }
}
