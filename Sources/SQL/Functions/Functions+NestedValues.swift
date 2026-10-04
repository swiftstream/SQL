//
//  Functions+NestedValues.swift
//  SwifQL
//

import Foundation

extension Fn.Name {
    public static let listValue: Self = .init("list_value")
    public static let arrayValue: Self = .init("array_value")
    public static let map: Self = .init("map")
}

extension Fn {
    private static func nestedValueArguments(_ values: [SQLable]) -> [SQLPart] {
        var parts: [SQLPart] = []
        for (index, value) in values.enumerated() {
            if index > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: value.parts)
        }
        return parts
    }

    public static func listValue(_ values: SQLable...) -> SQLable {
        listValue(values)
    }

    public static func listValue(_ values: [SQLable]) -> SQLable {
        build(.listValue, body: nestedValueArguments(values))
    }

    public static func arrayValue(_ values: SQLable...) -> SQLable {
        arrayValue(values)
    }

    public static func arrayValue(_ values: [SQLable]) -> SQLable {
        precondition(!values.isEmpty, "arrayValue requires at least one value")
        return build(.arrayValue, body: nestedValueArguments(values))
    }

    public static func map(_ keys: SQLable, _ values: SQLable) -> SQLable {
        build(.map, body: nestedValueArguments([keys, values]))
    }
}
