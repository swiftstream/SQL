//
//  Array+SQLable.swift
//
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

extension Array: SQLable where Element: SQLable {
    public var parts: [SQLPart] {
        if let _ = Element.self as? AnySQLEnum.Type {
            let values = compactMap {
                ($0 as? AnySQLEnum)?.anyRawValue as? String
            }.joined(separator: ",")
            return [SQLPartSafeValue("{\(values)}")]
        }
        if let s = self as? SQLCodable {
            return [SQLPartUnsafeValue(s)]
        } else {
            return separator(.comma).parts
        }
    }
}

extension Array: RowField where Element: SQLable {}

extension Array where Element: SQLable {
    public func separator(_ separator: SQLableArraySeparator) -> SQLable {
        var parts: [SQLPart] = []
        for (i, v) in enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return SQLableParts(rawParts: parts)
    }
}

extension Array: SQLPart where Element: SQLable {}

extension Array: SQLPartArray where Element: SQLable {
    public var elements: [SQLable] { self }
}
