//
//  SQLable+QuantifiedComparison.swift
//  SQL
//

import Foundation

public func ANY(_ operand: any SQLable) -> SQLable {
    let operandParts = operand.parts
    return _sqlQuantifier("ANY", operandParts: operandParts)
}

public func ANY(
    @SQLBuilder _ body: () -> SQLContent
) -> SQLable {
    let statement = body()
    let operandParts = statement.parts
    return _sqlQuantifier("ANY", operandParts: operandParts)
}

public func All(_ operand: any SQLable) -> SQLable {
    let operandParts = operand.parts
    return _sqlQuantifier("ALL", operandParts: operandParts)
}

public func All(
    @SQLBuilder _ body: () -> SQLContent
) -> SQLable {
    let statement = body()
    let operandParts = statement.parts
    return _sqlQuantifier("ALL", operandParts: operandParts)
}

public func Some(_ operand: any SQLable) -> SQLable {
    let operandParts = operand.parts
    return _sqlQuantifier("SOME", operandParts: operandParts)
}

public func Some(
    @SQLBuilder _ body: () -> SQLContent
) -> SQLable {
    let statement = body()
    let operandParts = statement.parts
    return _sqlQuantifier("SOME", operandParts: operandParts)
}

private func _sqlQuantifier(
    _ keyword: String,
    operandParts: [SQLPart]
) -> SQLable {
    var parts: [SQLPart] = [
        SQLPartOperator(keyword),
        SQLPartOperator.space,
        SQLPartOperator.openBracket
    ]
    parts.append(contentsOf: operandParts)
    parts.append(SQLPartOperator.closeBracket)
    return SQLableParts(rawParts: parts)
}
