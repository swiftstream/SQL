//
//  SwifQLable+Limit.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

//MARK: LIMIT

extension SwifQLable {
    public func limit(_ value: SwifQLable) -> SwifQLable {
        let parts: [SwifQLPart] = [SwifQLPartOperator.space, SwifQLPartOperator.limit, SwifQLPartOperator.space] + value.parts
        return structurallyAppending(SwifQLableParts(parts: parts))
    }

    /// Appends DuckDB's exact percentage LIMIT form without changing the
    /// established row-count overload.
    public func limit(percent value: SwifQLable) -> SwifQLable {
        var parts: [SwifQLPart] = [SwifQLPartOperator.space, SwifQLPartOperator.limit, SwifQLPartOperator.space]
        parts.append(contentsOf: value.parts)
        parts.append(SwifQLPartOperator.custom("%"))
        return structurallyAppending(SwifQLableParts(parts: parts))
    }
}
