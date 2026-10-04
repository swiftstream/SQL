//
//  SQLJoinBuilder.swift
//  App
//
//  Created by Mihael Isaev on 22/02/2019.
//

import Foundation

public struct JoinMode {
    let parts: [SQLPartOperator]
    
    public init (_ parts: SQLPartOperator...) {
        self.parts = parts
    }
    
    public init (_ parts: [SQLPartOperator]) {
        self.parts = parts
    }
    
    public static var none: JoinMode { .init(.join) }
    
    public static var left: JoinMode { .init(.left, .space, .join) }
    public static var leftLateral: JoinMode { .init(.left, .space, .join, .space, .lateral) }
    
    public static var leftOuter: JoinMode { .init(.left, .space, .outer, .space, .join) }
    public static var leftOuterLateral: JoinMode { .init(.left, .space, .outer, .space, .join, .space, .lateral) }

    public static var right: JoinMode { .init(.right, .space, .join) }
    public static var rightLateral: JoinMode { .init(.right, .space, .join, .space, .lateral) }

    public static var rightOuter: JoinMode { .init(.right, .space, .outer, .space, .join) }
    public static var rightOuterLateral: JoinMode { .init(.right, .space, .outer, .space, .join, .space, .lateral) }

    public static var inner: JoinMode { .init(.inner, .space, .join) }
    public static var outer: JoinMode { .init(.outer, .space, .join) }
    
    public static var cross: JoinMode { .init(.cross, .space, .join) }
    public static var crossLateral: JoinMode { .init(.cross, .space, .join, .space, .lateral) }

    public static var full: JoinMode { .init(.custom("FULL"), .space, .join) }
    public static var fullOuter: JoinMode { .init(.custom("FULL"), .space, .outer, .space, .join) }

    public static var semi: JoinMode { .init(.custom("SEMI"), .space, .join) }
    public static var anti: JoinMode { .init(.custom("ANTI"), .space, .join) }

    public static var asOf: JoinMode { .init(.custom("ASOF"), .space, .join) }
    public static var asOfLeft: JoinMode { .init(.custom("ASOF"), .space, .left, .space, .join) }

    public static var positional: JoinMode { .init(.custom("POSITIONAL"), .space, .join) }
    public static var natural: JoinMode { .init(.custom("NATURAL"), .space, .join) }
    public static var naturalInner: JoinMode { .init(.custom("NATURAL"), .space, .inner, .space, .join) }
    public static var naturalLeft: JoinMode { .init(.custom("NATURAL"), .space, .left, .space, .join) }
    public static var naturalRight: JoinMode { .init(.custom("NATURAL"), .space, .right, .space, .join) }
    public static var naturalFull: JoinMode { .init(.custom("NATURAL"), .space, .custom("FULL"), .space, .join) }
    public static var naturalFullOuter: JoinMode {
        .init(.custom("NATURAL"), .space, .custom("FULL"), .space, .outer, .space, .join)
    }
}

public struct SQLJoinBuilder: SQLable {
    let mode: JoinMode
    let table: SQLable
    let matchCondition: SQLable?
    let predicates: SQLable?
    private let usingColumns: [String]?
    
    public init (_ mode: JoinMode? = nil, _ table: SQLable, on predicates: SQLable? = nil) {
        self.mode = mode ?? .none
        self.table = table
        self.matchCondition = nil
        self.predicates = predicates
        self.usingColumns = nil
    }

    init (_ mode: JoinMode, _ table: SQLable, using columns: [KeyPathLastPath]) {
        self.mode = mode
        self.table = table
        self.matchCondition = nil
        self.predicates = nil
        self.usingColumns = columns.map(\.lastPath)
    }

    public init(
        _ mode: JoinMode? = nil,
        _ table: SQLable,
        matchCondition: SQLable,
        on predicates: SQLable? = nil
    ) {
        self.mode = mode ?? .none
        self.table = table
        self.matchCondition = matchCondition
        self.predicates = predicates
        self.usingColumns = nil
    }

    public init(
        _ mode: JoinMode,
        _ table: SQLable,
        matchCondition: SQLable,
        using columns: [KeyPathLastPath]
    ) {
        precondition(!columns.isEmpty, "JOIN MATCH_CONDITION USING requires at least one column")
        self.mode = mode
        self.table = table
        self.matchCondition = matchCondition
        self.predicates = nil
        self.usingColumns = columns.map(\.lastPath)
    }
    
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        parts.appendSpaceIfNeeded()
        parts.append(contentsOf: mode.parts)
        parts.append(o: .space)
        parts.append(contentsOf: table.parts)
        if let matchCondition {
            parts.append(o: .space, .custom("MATCH_CONDITION"), .space, .openBracket)
            parts.append(contentsOf: matchCondition.parts)
            parts.append(o: .closeBracket)
        }
        if let predicates = predicates {
            parts.append(o: .space)
            parts.append(o: .on)
            parts.append(o: .space)
            parts.append(contentsOf: predicates.parts)
        } else if let usingColumns = usingColumns {
            parts.append(o: .space)
            parts.append(o: .using)
            parts.append(o: .space)
            parts.append(o: .openBracket)
            for (index, column) in usingColumns.enumerated() {
                if index > 0 {
                    parts.append(o: .comma)
                    parts.append(o: .space)
                }
                parts.append(SQLPartColumn(column))
            }
            parts.append(o: .closeBracket)
        }
        return parts
    }
}
