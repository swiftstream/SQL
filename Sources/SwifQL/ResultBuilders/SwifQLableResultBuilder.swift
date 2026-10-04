////
////  SQLableResultBuilder.swift
////  SwifQL
////
////  Created by Mihael Isaev on 11.04.2020.
////
//
//import Foundation
//
//@resultBuilder public struct SQLableResultBuilder {
//    public typealias Block = () -> SQLable
//    
//    /// Builds an empty view from an block containing no statements, `{ }`.
//    public static func buildBlock() -> SQLable { [] }
//    
//    /// Passes a single view written as a child view (e..g, `{ Text("Hello") }`) through unmodified.
//    public static func buildBlock(_ attrs: SQLable...) -> SQLable {
//        buildBlock(attrs)
//    }
//    
//    /// Passes a single view written as a child view (e..g, `{ Text("Hello") }`) through unmodified.
//    public static func buildBlock(_ attrs: [SQLable]) -> SQLable {
//        
//        ViewBuilderItems(items: attrs.flatMap { $0.viewBuilderItems })
//    }
//    
//    /// Provides support for "if" statements in multi-statement closures, producing an `Optional` view
//    /// that is visible only when the `if` condition evaluates `true`.
//    public static func buildIf(_ content: SQLable?) -> SQLable {
//        guard let content = content else { return [] }
//        return content
//    }
//    
//    /// Provides support for "if" statements in multi-statement closures, producing
//    /// ConditionalContent for the "then" branch.
//    public static func buildEither(first: SQLable) -> SQLable {
//        first
//    }
//
//    /// Provides support for "if-else" statements in multi-statement closures, producing
//    /// ConditionalContent for the "else" branch.
//    public static func buildEither(second: SQLable) -> SQLable {
//        second
//    }
//}
//
//public protocol SQLableResultBuilderItem {
//    var expressions: [SQLable] { get }
//}
//
//extension SQLable: SQLableResultBuilderItem {
//    public var expressions: [SQLable] { [self] }
//}
//extension Array: SQLableResultBuilderItem where Element: SQLable {
//    public var expressions: [SQLable] { self }
//}
//extension Optional: SQLableResultBuilderItem where Wrapped: SQLable {
//    public var expressions: [SQLable] {
//        switch self {
//        case .none: return []
//        case .some(let value): return [value]
//        }
//    }
//}
