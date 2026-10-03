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

public protocol SwifQLUniversalKeyPathSimple: KeyPathLastPath {
    var path: String { get }
    var lastPath: String { get }
}

public protocol SwifQLUniversalKeyPath {
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
public func => (lhs: SwifQLable, rhs: Type) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .custom("::"))
    parts.append(SwifQLPartType(rhs))
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}
/// e.g. `"hello" as "title"`
public func => (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var postfix: [SwifQLPart] = []
    postfix.append(o: .space)
    postfix.append(o: .as)
    postfix.append(o: .space)
    if let rhs = rhs as? SwifQLUniversalKeyPathSimple {
        postfix.append(SwifQLPartAlias(rhs.lastPath))
    } else if let _ = rhs as? _AliasKeyPath {
        postfix.append(contentsOf: rhs.parts)
    } else if let _ = rhs as? TableAlias {
        postfix.append(contentsOf: rhs.parts)
    } else if let schemaWithTable = rhs as? Path.SchemaWithTable {
        postfix.append(SwifQLPartAlias(schemaWithTable.table))
    } else if let table = rhs as? Path.Table {
        postfix.append(SwifQLPartAlias(table.name))
    } else if let kp = rhs as? Keypathable {
        postfix.append(SwifQLPartAlias(kp.lastPath))
    } else {
        postfix.append(SwifQLPartAlias(String(describing: rhs)))
    }
    return _SwifQLStructuralComposition.appendingPostfix(postfix, to: lhs)
}

prefix operator =>
/// write `=>"aliasName"` in Swift
/// to reach `"aliasName"` in SQL
public prefix func => (rhs: String) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(SwifQLPartAlias(rhs))
    return SwifQLableParts(parts: parts)
}

//MARK: - Basic arithmetic functions
public func + (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("+"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

infix operator ++: AdditionPrecedence
public func ++ (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("+"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

public func - (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("-"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

infix operator --: AdditionPrecedence
public func -- (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("-"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

public func * (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("*"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

infix operator **: AdditionPrecedence
public func ** (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("*"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

public func / (lhs: SwifQLable, rhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = lhs.parts
    parts.append(o: .space)
    parts.append(o: .custom("/"))
    parts.append(o: .space)
    parts.append(contentsOf: rhs.parts)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

//% prefix for LIKE
prefix operator %
prefix public func %(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .custom("%"))
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}

//% postfix for LIKE
postfix operator %
postfix public func %(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .custom("%"))
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}

//1 opening bracket
prefix operator |
prefix public func |(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}
//2 opening brackets
prefix operator ||
prefix public func ||(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}
//3 opening brackets
prefix operator |||
prefix public func |||(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}
//4 opening brackets
prefix operator ||||
prefix public func ||||(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}
//5 opening brackets
prefix operator |||||
prefix public func |||||(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}
//6 opening brackets
prefix operator ||||||
prefix public func ||||||(lhs: SwifQLable) -> SwifQLable {
    var parts: [SwifQLPart] = []
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(o: .openBracket)
    parts.append(contentsOf: lhs.parts)
    return SwifQLableParts(rawParts: parts)
}

//1 closing bracket
postfix operator |
postfix public func |(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//2 closing brackets
postfix operator ||
postfix public func ||(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//3 closing brackets
postfix operator |||
postfix public func |||(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//4 closing brackets
postfix operator ||||
postfix public func ||||(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//5 closing brackets
postfix operator |||||
postfix public func |||||(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}
//6 closing brackets
postfix operator ||||||
postfix public func ||||||(rhs: SwifQLable) -> SwifQLable {
    var parts = rhs.parts
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    parts.append(o: .closeBracket)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: rhs, resultParts: parts)
}

postfix operator *
postfix public func *(lhs: SwifQLable) -> SwifQLable {
    var parts = lhs.parts
    parts.appendSpaceIfNeeded()
    parts.append(SwifQLPartOperator("*", semanticRole: .starProjection))
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}

postfix operator .*
postfix public func .*(lhs: SwifQLable) -> SwifQLable {
    var parts = lhs.parts
    parts.append(SwifQLPartOperator(".*", semanticRole: .starProjection))
    parts.append(o: .space)
    return _SwifQLStructuralComposition.reconstructingWholeValueTransform(from: lhs, resultParts: parts)
}
