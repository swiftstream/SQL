import Foundation

/// Typed SELECT postfix request produced by builder-form `Collate(_:)`,
/// `AtTimeZone(_:)`, and `AtLocal()`.
///
/// A request owns exactly one postfix fragment. It is deliberately not
/// `SQLable`: it can only attach to a currently open typed SELECT projection
/// continuation and can never render as a standalone expression.
public struct SQLSelectPostfixRequest {
    let parts: [SQLPart]

    init(parts: [SQLPart]) {
        self.parts = parts
    }
}

// MARK: - Builder continuations

/// `COLLATE <name>` postfix continuation for an already open SELECT expression.
/// The collation is structural identifier identity and never binds.
public func Collate(_ name: String) -> SQLSelectPostfixRequest {
    SQLSelectPostfixRequest(parts: [SQLPartOperator.collate, SQLPartOperator.space, SQLPartIdentifier(name)])
}

/// `COLLATE <schema>.<name>` postfix continuation with structural identifier qualifiers.
public func Collate(_ collation: DB.Object) -> SQLSelectPostfixRequest {
    var parts: [SQLPart] = [SQLPartOperator.collate, SQLPartOperator.space]
    parts.append(contentsOf: collation.parts)
    return SQLSelectPostfixRequest(parts: parts)
}

/// `AT TIME ZONE <expression>` postfix continuation; the zone stays an
/// ordinary bindable SQLable.
public func AtTimeZone(_ zone: SQLable) -> SQLSelectPostfixRequest {
    var parts: [SQLPart] = [
        SQLPartOperator.custom("AT"),
        SQLPartOperator.space,
        SQLPartOperator.timeZone,
        SQLPartOperator.space
    ]
    parts.append(contentsOf: zone.parts)
    return SQLSelectPostfixRequest(parts: parts)
}

/// `AT LOCAL` postfix continuation.
public func AtLocal() -> SQLSelectPostfixRequest {
    SQLSelectPostfixRequest(parts: [SQLPartOperator.custom("AT"), SQLPartOperator.space, SQLPartOperator.custom("LOCAL")])
}

// MARK: - Inline expressions

/// `expression COLLATE <name>` as an ordinary SQLable; the collation is
/// structural identifier identity and never binds.
public func Collate(_ expression: SQLable, _ name: String) -> SQLable {
    Collate(expression, DB.Object(name))
}

/// `expression COLLATE <identifier>` as an ordinary SQLable; schema/catalog
/// qualifiers stay structural.
public func Collate(_ expression: SQLable, _ collation: DB.Object) -> SQLable {
    var parts = expression.parts
    parts.appendSpaceIfNeeded()
    parts.append(o: .collate, .space)
    parts.append(contentsOf: collation.parts)
    return SQLableParts(rawParts: parts)
}

/// `expression AT TIME ZONE <zone>` as an ordinary SQLable; the zone keeps
/// ordinary binding.
public func AtTimeZone(_ expression: SQLable, _ zone: SQLable) -> SQLable {
    var parts = expression.parts
    parts.appendSpaceIfNeeded()
    parts.append(o: .custom("AT"), .space, .timeZone, .space)
    parts.append(contentsOf: zone.parts)
    return SQLableParts(rawParts: parts)
}

/// `expression AT LOCAL` as an ordinary SQLable.
public func AtLocal(_ expression: SQLable) -> SQLable {
    var parts = expression.parts
    parts.appendSpaceIfNeeded()
    parts.append(o: .custom("AT"), .space, .custom("LOCAL"))
    return SQLableParts(rawParts: parts)
}
