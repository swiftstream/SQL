//
//  SQLable+OrderBy.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

public struct OrderByItem: SQLable {
    // MARK: - Elements
    
    let elements: [SQLable]
    
    // MARK: - Direction
    
    public enum Direction {
        case asc, desc
        
        var `operator`: SQLPartOperator {
            switch self {
            case .asc: return .asc
            case .desc: return .desc
            }
        }
    }
    
    let direction: Direction
    
    // MARK: - Nulls
    
    public enum Nulls {
        case first, last
        
        var `operator`: SQLPartOperator {
            switch self {
            case .first: return .first
            case .last: return .last
            }
        }
    }
    
    let nulls: Nulls?
    
    // MARK: - Public static initializers

    // MARK: Direction

    /// Convenient method for situations if ascending flag is known only during runtime
    public static func direction(_ value: Direction, _ elements: SQLable..., nulls: Nulls? = nil) -> OrderByItem {
        direction(value, elements, nulls: nulls)
    }

    /// Convenient method for situations if ascending flag is known only during runtime
    public static func direction(_ value: Direction, _ elements: [SQLable], nulls: Nulls? = nil) -> OrderByItem {
        OrderByItem(elements: elements, direction: value, nulls: nulls)
    }
    
    // MARK: Ascending
    
    public static func asc(_ elements: SQLable...) -> OrderByItem {
        asc(elements, nulls: nil)
    }
    
    public static func asc(_ elements: [SQLable]) -> OrderByItem {
        asc(elements, nulls: nil)
    }
    
    public static func asc(_ elements: SQLable..., nulls: Nulls?) -> OrderByItem {
        asc(elements, nulls: nulls)
    }
    
    public static func asc(_ elements: [SQLable], nulls: Nulls?) -> OrderByItem {
        OrderByItem(elements: elements, direction: .asc, nulls: nulls)
    }
    
    // MARK: Descending
    
    public static func desc(_ elements: SQLable...) -> OrderByItem {
        desc(elements, nulls: nil)
    }
    
    public static func desc(_ elements: [SQLable]) -> OrderByItem {
        desc(elements, nulls: nil)
    }
    
    public static func desc(_ elements: SQLable..., nulls: Nulls?) -> OrderByItem {
        desc(elements, nulls: nulls)
    }
    
    public static func desc(_ elements: [SQLable], nulls: Nulls?) -> OrderByItem {
        OrderByItem(elements: elements, direction: .desc, nulls: nulls)
    }
    
    // MARK: Random
    
    /// Returns results in a random order. Hybrid operator that provides proper sintaxis acording to used language.
    public static var random: SQLHybridOperator {
        .random
    }
    
    // MARK: - SQLable
    
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        for (i, v) in elements.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .space)
        parts.append(o: direction.operator)
        if let nulls = nulls {
            parts.append(o: .space)
            parts.append(o: .nulls)
            parts.append(o: .space)
            parts.append(o: nulls.operator)
        }
        return parts
    }
}

//MARK: ORDER BY

extension SQLable {
    /// Order query results by some rows ascending or descending
    /// # Simple example
    /// ```swift
    /// .orderBy(.asc(\User.email), .desc(\User.firstName))
    /// ```
    /// # Raw SQL (in PostgreSQL syntax)
    /// ```sql
    /// ORDER BY "User"."email" ASC, "User"."firstName" DESC
    /// ```
    /// # Raw SQL (in MySQL syntax)
    /// ```sql
    /// ORDER BY "User"."email" ASC, "User"."firstName" DESC
    /// ```
    ///
    /// # PostgreSQL nulls example
    /// ```swift
    /// .orderBy(.asc(\User.email, nulls: .first), .desc(\User.firstName, nulls: .last))
    /// ```
    /// # Raw SQL
    /// ```sql
    /// ORDER BY "User"."email" ASC NULLS FIRST, "User"."firstName" DESC NULLS LAST
    /// ```
    ///
    /// # MySQL nulls example
    /// ```swift
    /// .orderBy(.asc(\User.email == nil, \User.email), .desc(\User.firstName != nil, \User.firstName))
    /// ```
    /// # Raw SQL
    /// ```sql
    /// ORDER BY User.email IS NULL, User.email ASC, User.firstName IS NOT NULL, User.firstName DESC
    /// ```
    ///
    
    public func orderBy(_ field: SQLHybridOperator) -> SQLable {
        let clause = SQLOrderByPart(
            owner: structuralOwner(for: .orderBy),
            items: [field.parts]
        )
        let fragment = SQLableParts(parts: [SQLPartOperator.space, clause])
        return structurallyAppending(fragment)
    }

    public func orderBy(_ field: SQLable) -> SQLable {
        let clause = SQLOrderByPart(
            owner: structuralOwner(for: .orderBy),
            items: [field.parts]
        )
        let fragment = SQLableParts(parts: [SQLPartOperator.space, clause])
        return structurallyAppending(fragment)
    }
    
    public func orderBy(_ fields: OrderByItem...) -> SQLable {
        orderBy(fields)
    }
    
    public func orderBy(_ fields: [OrderByItem]) -> SQLable {
        let clause = SQLOrderByPart(
            owner: structuralOwner(for: .orderBy),
            items: fields.map(\.parts)
        )
        let fragment = SQLableParts(parts: [SQLPartOperator.space, clause])
        return structurallyAppending(fragment)
    }

}
