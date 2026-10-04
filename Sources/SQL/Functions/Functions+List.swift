//
//  Functions+List.swift
//  SwifQL
//

import Foundation

extension Fn.Name {
    public static let listTransform: Self = .init("list_transform")
    public static let listFilter: Self = .init("list_filter")
    public static let listReduce: Self = .init("list_reduce")
}

extension Fn {
    private static func listFunctionArguments(_ values: [SQLable]) -> [SQLPart] {
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

    public static func listTransform(_ list: SQLable, _ lambda: SQLable) -> SQLable {
        build(.listTransform, body: listFunctionArguments([list, lambda]))
    }

    public static func listFilter(_ list: SQLable, _ lambda: SQLable) -> SQLable {
        build(.listFilter, body: listFunctionArguments([list, lambda]))
    }

    public static func listReduce(_ list: SQLable, _ lambda: SQLable) -> SQLable {
        build(.listReduce, body: listFunctionArguments([list, lambda]))
    }

    public static func listReduce(
        _ list: SQLable,
        _ lambda: SQLable,
        _ initialValue: SQLable
    ) -> SQLable {
        build(.listReduce, body: listFunctionArguments([list, lambda, initialValue]))
    }
}
