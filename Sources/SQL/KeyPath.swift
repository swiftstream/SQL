//
//  KeyPath.swift
//  SwifQL
//
//  Created by Mihael Isaev on 05/11/2018.
//

import Foundation

public protocol KeyPathLastPath {
    var lastPath: String { get }
}

extension String: KeyPathLastPath {
    public var lastPath: String { self }
}

public protocol SQLUniversalKeyPathSimple: KeyPathLastPath {
    var path: String { get }
    var lastPath: String { get }
}

public protocol SQLUniversalKeyPath {
    associatedtype AType
    associatedtype AModel: Decodable
    associatedtype ARoot
    
    var path: String { get }
    var lastPath: String { get }
    var originalKeyPath: KeyPath<AModel, AType> { get }
}

//MARK: - Casting

infix operator => : AdditionPrecedence
/// e.g. `"1"::.text`
public func => (lhs: SQLable, rhs: Type) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .custom("::"))
    parts.append(SQLPartType(rhs))
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}
/// e.g. `"hello" as "title"`
public func => (lhs: SQLable, rhs: SQLable) -> SQLable {
    var postfix: [SQLPart] = []
    postfix.append(o: .space)
    postfix.append(o: .as)
    postfix.append(o: .space)
    if let rhs = rhs as? SQLUniversalKeyPathSimple {
        postfix.append(SQLPartAlias(rhs.lastPath))
    } else if let _ = rhs as? _AliasKeyPath {
        postfix.append(contentsOf: rhs.parts)
    } else if let _ = rhs as? TableAlias {
        postfix.append(contentsOf: rhs.parts)
    } else if let schemaWithTable = rhs as? Path.SchemaWithTable {
        postfix.append(SQLPartAlias(schemaWithTable.table))
    } else if let table = rhs as? Path.Table {
        postfix.append(SQLPartAlias(table.name))
    } else if let kp = rhs as? Keypathable {
        postfix.append(SQLPartAlias(kp.lastPath))
    } else {
        postfix.append(SQLPartAlias(String(describing: rhs)))
    }
    return _SQLStructuralComposition.appendingPostfix(postfix, to: lhs)
}

prefix operator =>
/// write `=>"aliasName"` in Swift
/// to reach `"aliasName"` in SQL
public prefix func => (rhs: String) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(SQLPartAlias(rhs))
    return SQLableParts(parts: parts)
}

//MARK: - Basic arithmetic functions
@_disfavoredOverload
public func + (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("+"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

infix operator ++: AdditionPrecedence
public func ++ (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("+"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

@_disfavoredOverload
public func - (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("-"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

infix operator --: AdditionPrecedence
public func -- (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("-"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

@_disfavoredOverload
public func * (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("*"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

infix operator **: AdditionPrecedence
public func ** (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("*"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

@_disfavoredOverload
public func / (lhs: SQLable, rhs: SQLable) -> SQLable {
    var parts: [SQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("/"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

//% prefix for LIKE
prefix operator %
prefix public func %(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .custom("%"))
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}

//% postfix for LIKE
postfix operator %
postfix public func %(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .custom("%"))
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}

//1 opening bracket
prefix operator |
prefix public func |(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}
//2 opening brackets
prefix operator ||
prefix public func ||(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}
//3 opening brackets
prefix operator |||
prefix public func |||(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}
//4 opening brackets
prefix operator ||||
prefix public func ||||(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}
//5 opening brackets
prefix operator |||||
prefix public func |||||(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}
//6 opening brackets
prefix operator ||||||
prefix public func ||||||(lhs: SQLable) -> SQLable {
    var parts: [SQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SQLableParts(rawParts: parts)
}

//1 closing bracket
postfix operator |
postfix public func |(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//2 closing brackets
postfix operator ||
postfix public func ||(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//3 closing brackets
postfix operator |||
postfix public func |||(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//4 closing brackets
postfix operator ||||
postfix public func ||||(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//5 closing brackets
postfix operator |||||
postfix public func |||||(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//6 closing brackets
postfix operator ||||||
postfix public func ||||||(rhs: SQLable) -> SQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}

postfix operator *
postfix public func *(lhs: SQLable) -> SQLable {
    var parts = lhs.parts
    parts.appendSpaceIfNeeded()
    parts.append(SQLPartOperator("*", semanticRole: .starProjection))
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

postfix operator .*
postfix public func .*(lhs: SQLable) -> SQLable {
    var parts = lhs.parts
    parts.append(SQLPartOperator(".*", semanticRole: .starProjection))
    parts.append(o: .space)
    return _SQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}
