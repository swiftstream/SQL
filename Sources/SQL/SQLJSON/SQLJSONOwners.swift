//
//  SQLJSONOwners.swift
//  SQL
//

import Foundation

/// Owns the argument snapshot and clause order for one SQL/JSON query function:
/// document, path, `PASSING`, then the owner's remaining clauses. Both required
/// arguments are read exactly once, and the direct runtime path occurrence is
/// the only value that receives the path grammar role.
private func sqlJSONOwner(
    keyword: String,
    document: SQLable,
    path: SQLable,
    owner: SQLJSONOwner,
    options: SQLJSONOptions
) -> SQLable {
    let documentParts = document.parts
    let pathParts = SQLJSONContextualValue.parts(
        for: path,
        role: .path,
        owner: owner
    )

    var parts: [SQLPart] = []
    parts.append(SQLPartOperator.custom(keyword))
    parts.append(o: .openBracket)
    parts.append(contentsOf: documentParts)
    parts.append(o: .comma, .space)
    parts.append(contentsOf: pathParts)
    if !options.passingEntries.isEmpty {
        parts.append(o: .space, .custom("PASSING"), .space)
        for (index, entry) in options.passingEntries.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: entry)
        }
    }
    parts.append(contentsOf: options.tailParts)
    parts.append(o: .closeBracket)
    return SQLableParts(parts: parts)
}

// MARK: - JSON_EXISTS

public func JSONExists(_ document: SQLable, _ path: SQLable) -> SQLable {
    sqlJSONOwner(
        keyword: "JSON_EXISTS",
        document: document,
        path: path,
        owner: .jsonExists,
        options: .empty
    )
}

public func JSONExists(
    _ document: SQLable,
    _ path: SQLable,
    @JSONExistsBuilder _ options: () -> SQLJSONOptions
) -> SQLable {
    sqlJSONOwner(
        keyword: "JSON_EXISTS",
        document: document,
        path: path,
        owner: .jsonExists,
        options: options()
    )
}

// MARK: - JSON_VALUE

public func JSONValue(_ document: SQLable, _ path: SQLable) -> SQLable {
    sqlJSONOwner(
        keyword: "JSON_VALUE",
        document: document,
        path: path,
        owner: .jsonValue,
        options: .empty
    )
}

public func JSONValue(
    _ document: SQLable,
    _ path: SQLable,
    @JSONValueBuilder _ options: () -> SQLJSONOptions
) -> SQLable {
    sqlJSONOwner(
        keyword: "JSON_VALUE",
        document: document,
        path: path,
        owner: .jsonValue,
        options: options()
    )
}

// MARK: - JSON_QUERY

public func JSONQuery(_ document: SQLable, _ path: SQLable) -> SQLable {
    sqlJSONOwner(
        keyword: "JSON_QUERY",
        document: document,
        path: path,
        owner: .jsonQuery,
        options: .empty
    )
}

public func JSONQuery(
    _ document: SQLable,
    _ path: SQLable,
    @JSONQueryBuilder _ options: () -> SQLJSONOptions
) -> SQLable {
    sqlJSONOwner(
        keyword: "JSON_QUERY",
        document: document,
        path: path,
        owner: .jsonQuery,
        options: options()
    )
}
