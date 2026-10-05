//
//  SwifQL.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

public struct SQLContent: SQLable {
    public var parts: [SQLPart]

    public init() {
        self.parts = [SQLStructuralFramePart(region: .statement)]
    }

    public init(_ query: SQLable) {
        self.parts = query.parts
    }
}

public var SQL: SQLContent {
    SQLContent()
}

public func SQL(_ query: SQLable) -> SQLContent {
    SQLContent(query)
}

public func SQL(@SQLBuilder _ content: () -> SQLBuilder.Root) -> SQLContent {
    content()
}

@available(*, deprecated, renamed: "SQL")
public var SwifQL: SQLContent { SQL }

@available(*, deprecated, renamed: "SQL")
public func SwifQL(_ query: SQLable) -> SQLContent {
    SQL(query)
}

@available(*, deprecated, renamed: "SQL")
public func SwifQL(@SQLBuilder _ content: () -> SQLBuilder.Root) -> SQLContent {
    SQL(content())
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
