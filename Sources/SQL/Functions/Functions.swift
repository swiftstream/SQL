//
//  Functions.swift
//  SwifQL
//
//  Created by Mihael Isaev on 04/11/2018.
//

import Foundation

public struct Fn {}

extension Fn {
    public struct Name: Sendable {
        let name: String
        
        public init (_ name: String) {
            self.name = name
        }
        
        public static func custom(_ name: String) -> Name { .init(name) }
        
        var part: SQLPartOperator { .init(name) }
    }
}

//MARK: Function builders

extension Fn {
    public static func build(_ fn: Name) -> SQLable {
        build(fn, body: nil)
    }
    public static func build(_ fn: Name, body: SQLPart...) -> SQLable {
        build(fn, body: body)
    }
    public static func build(_ fn: Name, body: [SQLPart]? = nil) -> SQLable {
        var parts: [SQLPart] = []
        parts.append(f: fn)
        if let body = body {
            parts.append(o: .openBracket)
            parts.append(contentsOf: body)
            parts.append(o: .closeBracket)
        }
        return SQLableParts(parts: parts)
    }
}

public func Select(_ queryPart: SQLable...) -> SQLable {
    Select(queryPart)
}

public func Select(_ queryParts: [SQLable]) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .select)
    parts.append(o: .space)
    for (i, q) in queryParts.enumerated() {
        if i > 0 {
            parts.append(o: .comma)
            parts.append(o: .space)
        }
        parts.append(contentsOf: q.parts)
    }
    return SQLableParts(parts: parts)
}

public var Select: SQLable { Fn.build(.custom("SELECT")) }

//MARK: [SQLPart] extension

extension Array where Element == SQLPart {
    public mutating func appendSpaceIfNeeded() {
        if count == 0 { return }
        if let last = last as? SQLPartOperator, last._value == " " {
            return
        }
        append(o: .space)
    }
    public mutating func append(f: Fn.Name) {
        append(f.part)
    }
    public mutating func append(o: SQLPartOperator...) {
        o.forEach { append($0) }
    }
    public mutating func append(h: SQLHybridOperator...) {
        h.forEach { append($0) }
    }
    public mutating func append(safe value: Any) {
        append(SQLPartSafeValue(value))
    }
}
