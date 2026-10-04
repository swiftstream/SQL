//
//  NewColumn.swift
//  
//
//  Created by Mihael Isaev on 26.01.2020.
//

import Foundation

public class NewColumn: SQLable {
    var name: String
    var type: Type
    var `default`: SQLable?
    var constraints: [SQLable] = []
    
    public init(_ name: String, _ type: Type) {
        self.name = name
        self.type = type
    }
    
    @discardableResult
    public func `default`(constant v: Any) -> Self {
        `default` = SQLableParts(parts: SQLPartSafeValue(v))
        return self
    }
    
    @discardableResult
    public func `default`(expression: SQLable) -> Self {
        `default` = expression
        return self
    }
    
    @discardableResult
    public func `default`(sequence name: String) -> Self {
        `default` = SQLableParts(parts: Op.custom(name))
        return self
    }
    
    @discardableResult
    public func constraint(expression: SQLable) -> Self {
        constraints.append(expression)
        return self
    }
    
    @discardableResult
    public func primaryKey() -> Self {
        constraints.append(SQL.root.primary.key)
        return self
    }
    
    @discardableResult
    public func unique() -> Self {
        constraints.append(SQL.root.unique)
        return self
    }
    
    @discardableResult
    public func notNull() -> Self {
        constraints.append(SQL.root.not.null)
        return self
    }
    
    @discardableResult
    public func check(name: String? = nil, _ expression: SQLable) -> Self {
        guard expression.parts.count > 0 else { return self }
        var parts: [SQLPart] = []
        if let name = name {
            parts.append(o: .constraint)
            parts.append(o: .space)
            parts.append(SQLPartColumn(name))
        }
        parts.appendSpaceIfNeeded()
        parts.append(o: .check)
        parts.append(o: .openBracket)
        parts.append(contentsOf: expression.parts)
        parts.append(o: .closeBracket)
        constraints.append(SQLableParts(parts: parts))
        return self
    }
    
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(SQLPartType(type))
        if let expression = `default` {
            parts.append(o: .space)
            parts.append(contentsOf: expression.parts)
        }
        constraints.forEach { expression in
            parts.append(o: .space)
            parts.append(contentsOf: expression.parts)
        }
        return parts
    }
}
