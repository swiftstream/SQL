//
//  SQLable+Case.swift
//  SwifQL
//
//  Created by Mihael Isaev on 15/02/2019.
//

import Foundation

public class Case {
    var parts: [SQLPart] = []
    
    public init (_ expression: SQLable? = nil) {
        parts.append(o: .case)
        if let expression = expression {
            parts.append(o: .space)
            parts.append(contentsOf: expression.parts)
        }
    }
    
    public static func when(_ expression: SQLable) -> Case {
        Case().when(expression)
    }
    
    public func when(_ expression: SQLable) -> Case {
        parts.appendSpaceIfNeeded()
        parts.append(o: .when)
        parts.append(o: .space)
        parts.append(contentsOf: expression.parts)
        return self
    }
    
    public func then(_ expression: SQLable?) -> Case {
        parts.appendSpaceIfNeeded()
        parts.append(o: .then)
        parts.append(o: .space)
        if let expression = expression {
            parts.append(contentsOf: expression.parts)
        } else {
            parts.append(o: .null)
        }
        return self
    }
    
    public func `else`(_ expression: SQLable?) -> Case {
        parts.appendSpaceIfNeeded()
        parts.append(o: .else)
        parts.append(o: .space)
        if let expression = expression {
            parts.append(contentsOf: expression.parts)
        } else {
            parts.append(o: .null)
        }
        return self
    }
    
    public var end: SQLable {
        parts.appendSpaceIfNeeded()
        parts.append(o: .end)
        return SQLableParts(parts: parts)
    }
}
