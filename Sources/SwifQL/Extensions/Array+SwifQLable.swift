//
//  Array+SwifQLable.swift
//
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

extension Array: SwifQLable where Element: SwifQLable {
    public var parts: [SwifQLPart] {
        if let _ = Element.self as? AnySwifQLEnum.Type {
            let values = compactMap {
                ($0 as? AnySwifQLEnum)?.anyRawValue as? String
            }.joined(separator: ",")
            return [SwifQLPartSafeValue("{\(values)}")]
        }
        if let s = self as? SwifQLCodable {
            return [SwifQLPartUnsafeValue(s)]
        } else {
            return separator(.comma).parts
        }
    }
}

extension Array: RowField where Element: SwifQLable {}

extension Array where Element: SwifQLable {
    public func separator(_ separator: SwifQLableArraySeparator) -> SwifQLable {
        var parts: [SwifQLPart] = []
        for (i, v) in enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        return SwifQLableParts(rawParts: parts)
    }
}

extension Array: SwifQLPart where Element: SwifQLable {}

extension Array: SwifQLPartArray where Element: SwifQLable {
    public var elements: [SwifQLable] { self }
}
