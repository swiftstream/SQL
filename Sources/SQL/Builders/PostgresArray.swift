//
//  PostgresArray.swift
//  SwifQL
//
//  Created by Mihael Isaev on 14/02/2019.
//

import Foundation

public typealias PgArray = PostgresArray

public struct PostgresArray: SQLable {
    public enum EmptyMode {
        case simple, dollar
    }
    
    public var parts: [SQLPart] = []
    
    public init (_ items: SQLable..., emptyMode: EmptyMode = .simple) {
        self.init(items, emptyMode: emptyMode)
    }
    
    public init (_ items: [SQLable], emptyMode: EmptyMode = .simple) {
        if items.count == 0 && emptyMode == .dollar {
            parts.append(o: .doubleDollar)
            parts.append(o: .openSquareBracket)
            parts.append(o: .closeSquareBracket)
            parts.append(o: .doubleDollar)
            return
        }
        parts.append(o: .array)
        parts.append(o: .openSquareBracket)
        for (i, v) in items.enumerated() {
            if i > 0 {
                parts.append(o: .comma)
                parts.append(o: .space)
            }
            parts.append(contentsOf: v.parts)
        }
        parts.append(o: .closeSquareBracket)
    }
}
