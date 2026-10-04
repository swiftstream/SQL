//
//  SwifQL.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

public struct SQL: SQLable {
    public var parts: [SQLPart]

    public init() {
        self.parts = [SQLStructuralFramePart(region: .statement)]
    }

    public init(_ query: SQLable) {
        self.parts = query.parts
    }

    public init(@SQLBuilder _ content: () -> SQLBuilder.Root) {
        self.parts = content().parts
    }

    public static var root: SQL { SQL() }
}

@available(*, deprecated, renamed: "SQL.root")
public var SwifQL: SQL { SQL.root }

@available(*, deprecated, renamed: "SQL")
public func SwifQL(_ query: SQLable) -> SQL {
    SQL(query)
}

@available(*, deprecated, renamed: "SQL")
public func SwifQL(@SQLBuilder _ content: () -> SQLBuilder.Root) -> SQL {
    SQL(content)
}

infix operator ~
public func ~ (lhs: SQLable, rhs: SQLable) -> SQLable {
    if lhs.parts.first is SQLStructuralFramePart {
        if rhs.parts.first is SQLStructuralFramePart {
            return SQLableParts(rawParts: lhs.parts + rhs.parts)
        }
        return _SQLStructuralComposition.append(
            lhs,
            parts: rhs.parts,
            spacing: .literal
        )
    }

    return SQLableParts(rawParts: lhs.parts + rhs.parts)
}
public func ~ (lhs: SQLable, rhs: SQLPartOperator) -> SQLable {
    let fragment = SQLableParts(parts: rhs)
    if lhs.parts.first is SQLStructuralFramePart {
        return _SQLStructuralComposition.append(
            lhs,
            parts: fragment.parts,
            spacing: .literal
        )
    }

    return SQLableParts(rawParts: lhs.parts + fragment.parts)
}
