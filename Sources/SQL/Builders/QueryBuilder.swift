//
//  QueryBuilder.swift
//  SQLCore
//
//  Created by Mihael Isaev on 19.12.2019.
//

import Foundation

public protocol QueryBuilderItemable {
    var values: [SQLable] { get }
}
public struct QueryBuilderItem: SQLable {
    public let parts: [SQLPart]
    public let values: [SQLable]
    public init (_ values: [SQLable]? = nil) {
        var parts: [SQLPart] = []
        if let values = values {
            values.forEach {
                parts.append(contentsOf: $0.parts)
            }
        }
        self.parts = parts
        self.values = values ?? []
    }
}
@resultBuilder public struct QueryBuilder {
    public typealias Block = () -> SQLable
    
    /// Builds an empty view from an block containing no statements, `{ }`.
    public static func buildBlock() -> SQLable { QueryBuilderItem() }
    
    /// Passes a single view written as a child view (e..g, `{ Text("Hello") }`) through unmodified.
    public static func buildBlock(_ attr: SQLable) -> SQLable {
        QueryBuilderItem([attr])
    }
    
    /// Passes a single view written as a child view (e..g, `{ Text("Hello") }`) through unmodified.
    public static func buildBlock(_ attrs: SQLable...) -> SQLable {
        QueryBuilderItem(attrs)
    }
    
    /// Passes a single view written as a child view (e..g, `{ Text("Hello") }`) through unmodified.
    public static func buildBlock(_ attrs: [SQLable]) -> SQLable {
        QueryBuilderItem(attrs)
    }
    
    /// Provides support for "if" statements in multi-statement closures, producing an `Optional` view
    /// that is visible only when the `if` condition evaluates `true`.
    public static func buildIf(_ content: SQLable?) -> SQLable {
        guard let content = content else { return QueryBuilderItem() }
        return QueryBuilderItem([content])
    }
    
    /// Provides support for "if" statements in multi-statement closures, producing
    /// ConditionalContent for the "then" branch.
    public static func buildEither(first: SQLable) -> SQLable {
        QueryBuilderItem([first])
    }

    /// Provides support for "if-else" statements in multi-statement closures, producing
    /// ConditionalContent for the "else" branch.
    public static func buildEither(second: SQLable) -> SQLable {
        QueryBuilderItem([second])
    }
}
