//
//  SQLJSONOptionNodes.swift
//  SQL
//

import Foundation

// MARK: - Finite SQL/JSON option vocabularies

public enum JSONReturningType: Sendable {
    case integer
    case jsonb
    case text
}

/// The formatted return-type vocabulary is deliberately narrower than the base
/// one: `FORMAT JSON` is verified only for `RETURNING TEXT`.
public enum JSONFormattedReturningType: Sendable {
    case text
}

public enum JSONReturningFormat: Sendable {
    case json
}

public enum JSONWrapperBehavior: Sendable {
    case conditional
    case unconditional
}

public enum JSONQuoteBehavior: Sendable {
    case onScalarString
}

// MARK: - Option nodes

/// One `PASSING` variable binding. The value stays an ordinary bindable
/// expression; only the name is structural identifier identity.
public struct JSONPassingNode {
    let entryParts: [SQLPart]

    init(_ value: SQLable, as name: String) {
        var parts = value.parts
        parts.append(o: .space, .custom("AS"), .space)
        parts.append(SQLPartIdentifier(name))
        entryParts = parts
    }
}

/// `RETURNING <type>` ownership for every SQL/JSON owner that accepts a plain
/// return type.
public struct JSONReturningNode {
    let fragmentParts: [SQLPart]

    init(_ type: JSONReturningType) {
        fragmentParts = jsonReturningParts(type)
    }
}

/// `RETURNING <type> FORMAT JSON` is a distinct node so owners that reject
/// `FORMAT` cannot accept it at compile time.
public struct JSONFormattedReturningNode {
    let fragmentParts: [SQLPart]

    init(_ type: JSONFormattedReturningType) {
        fragmentParts = jsonFormattedReturningParts(type)
    }
}

public struct JSONOnEmptyBehaviorNode {
    let fragmentParts: [SQLPart]

    init(keyword: String) {
        fragmentParts = jsonBehaviorParts(keyword, on: "EMPTY")
    }
}

public struct JSONOnErrorBehaviorNode {
    let fragmentParts: [SQLPart]

    init(keyword: String) {
        fragmentParts = jsonBehaviorParts(keyword, on: "ERROR")
    }
}

/// `DEFAULT <value> ON EMPTY`. The value is lowered with the exact owner
/// identity when the surrounding owner fixes the grammar role.
public struct JSONDefaultOnEmptyNode {
    let value: SQLable

    init(_ value: SQLable) {
        self.value = value
    }

    func fragmentParts(owner: SQLJSONOwner) -> [SQLPart] {
        jsonDefaultParts(value, on: "EMPTY", owner: owner)
    }
}

public struct JSONDefaultOnErrorNode {
    let value: SQLable

    init(_ value: SQLable) {
        self.value = value
    }

    func fragmentParts(owner: SQLJSONOwner) -> [SQLPart] {
        jsonDefaultParts(value, on: "ERROR", owner: owner)
    }
}

/// `TRUE | FALSE | UNKNOWN ON ERROR`, owned only by `JSON_EXISTS`.
public struct JSONBooleanOnErrorNode {
    let fragmentParts: [SQLPart]

    init(keyword: String) {
        fragmentParts = jsonBehaviorParts(keyword, on: "ERROR")
    }
}

public struct JSONEmptyResultOnEmptyNode {
    let fragmentParts: [SQLPart]

    init(result: String) {
        fragmentParts = jsonBehaviorParts("EMPTY \(result)", on: "EMPTY")
    }
}

public struct JSONEmptyResultOnErrorNode {
    let fragmentParts: [SQLPart]

    init(result: String) {
        fragmentParts = jsonBehaviorParts("EMPTY \(result)", on: "ERROR")
    }
}

public struct JSONWrapperBehaviorNode {
    let fragmentParts: [SQLPart]

    init(without: Bool, array: Bool, behavior: JSONWrapperBehavior?) {
        var parts: [SQLPart] = []
        parts.append(o: .space, .custom(without ? "WITHOUT" : "WITH"))
        switch behavior {
        case .conditional:
            parts.append(o: .space, .custom("CONDITIONAL"))
        case .unconditional:
            parts.append(o: .space, .custom("UNCONDITIONAL"))
        case nil:
            break
        }
        if array {
            parts.append(o: .space, .custom("ARRAY"))
        }
        parts.append(o: .space, .custom("WRAPPER"))
        fragmentParts = parts
    }
}

public struct JSONQuotesBehaviorNode {
    let fragmentParts: [SQLPart]

    init(keep: Bool, onScalarString: Bool) {
        var parts: [SQLPart] = []
        parts.append(o: .space, .custom(keep ? "KEEP" : "OMIT"), .space, .custom("QUOTES"))
        if onScalarString {
            parts.append(o: .space, .custom("ON"), .space, .custom("SCALAR"), .space, .custom("STRING"))
        }
        fragmentParts = parts
    }
}

private func jsonReturningParts(_ type: JSONReturningType) -> [SQLPart] {
    var parts: [SQLPart] = []
    parts.append(o: .space, .custom("RETURNING"), .space)
    switch type {
    case .integer:
        // The return-type token is dialect-owned grammar: PostgreSQL spells it
        // `INTEGER`, MySQL `SIGNED`. No portability mapping is applied to the
        // remaining vocabulary types.
        parts.append(
            SQLHybridOperator(
                SQLPartOperator("INTEGER"),
                SQLPartOperator("SIGNED")
            )
        )
    case .jsonb:
        parts.append(SQLPartOperator.custom("JSONB"))
    case .text:
        parts.append(SQLPartOperator.custom("TEXT"))
    }
    return parts
}

private func jsonFormattedReturningParts(_ type: JSONFormattedReturningType) -> [SQLPart] {
    var parts: [SQLPart] = []
    parts.append(o: .space, .custom("RETURNING"), .space)
    switch type {
    case .text:
        parts.append(SQLPartOperator.custom("TEXT"))
    }
    parts.append(o: .space, .custom("FORMAT"), .space, .custom("JSON"))
    return parts
}

private func jsonBehaviorParts(_ keyword: String, on slot: String) -> [SQLPart] {
    var parts: [SQLPart] = []
    parts.append(o: .space, .custom(keyword), .space, .custom("ON"), .space, .custom(slot))
    return parts
}

private func jsonDefaultParts(
    _ value: SQLable,
    on slot: String,
    owner: SQLJSONOwner
) -> [SQLPart] {
    var parts: [SQLPart] = []
    parts.append(o: .space, .custom("DEFAULT"), .space)
    parts.append(
        contentsOf: SQLJSONContextualValue.parts(
            for: value,
            role: .directRuntimeDefaultValue,
            owner: owner
        )
    )
    parts.append(o: .space, .custom("ON"), .space, .custom(slot))
    return parts
}

// MARK: - Exact public option call sites

public func Passing(_ value: SQLable, as name: String) -> JSONPassingNode {
    JSONPassingNode(value, as: name)
}

public func Returning(_ type: JSONReturningType) -> JSONReturningNode {
    JSONReturningNode(type)
}

public func Returning(
    _ type: JSONFormattedReturningType,
    format: JSONReturningFormat
) -> JSONFormattedReturningNode {
    JSONFormattedReturningNode(type)
}

public func NullOnEmpty() -> JSONOnEmptyBehaviorNode {
    JSONOnEmptyBehaviorNode(keyword: "NULL")
}

public func ErrorOnEmpty() -> JSONOnEmptyBehaviorNode {
    JSONOnEmptyBehaviorNode(keyword: "ERROR")
}

public func DefaultOnEmpty(_ value: SQLable) -> JSONDefaultOnEmptyNode {
    JSONDefaultOnEmptyNode(value)
}

public func NullOnError() -> JSONOnErrorBehaviorNode {
    JSONOnErrorBehaviorNode(keyword: "NULL")
}

public func ErrorOnError() -> JSONOnErrorBehaviorNode {
    JSONOnErrorBehaviorNode(keyword: "ERROR")
}

public func DefaultOnError(_ value: SQLable) -> JSONDefaultOnErrorNode {
    JSONDefaultOnErrorNode(value)
}

public func TrueOnError() -> JSONBooleanOnErrorNode {
    JSONBooleanOnErrorNode(keyword: "TRUE")
}

public func FalseOnError() -> JSONBooleanOnErrorNode {
    JSONBooleanOnErrorNode(keyword: "FALSE")
}

public func UnknownOnError() -> JSONBooleanOnErrorNode {
    JSONBooleanOnErrorNode(keyword: "UNKNOWN")
}

public func WithoutWrapper() -> JSONWrapperBehaviorNode {
    JSONWrapperBehaviorNode(without: true, array: false, behavior: nil)
}

public func WithoutArrayWrapper() -> JSONWrapperBehaviorNode {
    JSONWrapperBehaviorNode(without: true, array: true, behavior: nil)
}

public func WithWrapper() -> JSONWrapperBehaviorNode {
    JSONWrapperBehaviorNode(without: false, array: false, behavior: nil)
}

public func WithWrapper(_ behavior: JSONWrapperBehavior) -> JSONWrapperBehaviorNode {
    JSONWrapperBehaviorNode(without: false, array: false, behavior: behavior)
}

public func WithArrayWrapper() -> JSONWrapperBehaviorNode {
    JSONWrapperBehaviorNode(without: false, array: true, behavior: nil)
}

public func WithArrayWrapper(_ behavior: JSONWrapperBehavior) -> JSONWrapperBehaviorNode {
    JSONWrapperBehaviorNode(without: false, array: true, behavior: behavior)
}

public func KeepQuotes() -> JSONQuotesBehaviorNode {
    JSONQuotesBehaviorNode(keep: true, onScalarString: false)
}

public func KeepQuotes(_ behavior: JSONQuoteBehavior) -> JSONQuotesBehaviorNode {
    JSONQuotesBehaviorNode(keep: true, onScalarString: true)
}

public func OmitQuotes() -> JSONQuotesBehaviorNode {
    JSONQuotesBehaviorNode(keep: false, onScalarString: false)
}

public func OmitQuotes(_ behavior: JSONQuoteBehavior) -> JSONQuotesBehaviorNode {
    JSONQuotesBehaviorNode(keep: false, onScalarString: true)
}

public func EmptyArrayOnEmpty() -> JSONEmptyResultOnEmptyNode {
    JSONEmptyResultOnEmptyNode(result: "ARRAY")
}

public func EmptyObjectOnEmpty() -> JSONEmptyResultOnEmptyNode {
    JSONEmptyResultOnEmptyNode(result: "OBJECT")
}

public func EmptyArrayOnError() -> JSONEmptyResultOnErrorNode {
    JSONEmptyResultOnErrorNode(result: "ARRAY")
}

public func EmptyObjectOnError() -> JSONEmptyResultOnErrorNode {
    JSONEmptyResultOnErrorNode(result: "OBJECT")
}
