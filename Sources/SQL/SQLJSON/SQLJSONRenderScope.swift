//
//  SQLJSONRenderScope.swift
//  SQL
//

import Foundation

/// SQL/JSON grammar positions whose rendering policy may differ from the same
/// value in an ordinary expression. The names describe grammar ownership, not
/// products, so every dialect reads the same role identity.
enum SQLJSONGrammarRole {
    /// The path operand of a SQL/JSON query function.
    case path
    /// The parser-restricted direct runtime value of a `DEFAULT ... ON ...` clause.
    case directRuntimeDefaultValue
}

/// Exact SQL/JSON construct that opened a render scope.
struct SQLJSONOwner: Hashable, Sendable {
    let name: String

    static let jsonExists = SQLJSONOwner(name: "jsonExists")
    static let jsonValue = SQLJSONOwner(name: "jsonValue")
    static let jsonQuery = SQLJSONOwner(name: "jsonQuery")
}

/// Owns the value-semantic scope identity for the SQL/JSON grammar roles above.
/// The owner attaches scope; the selected dialect still decides whether an
/// unsafe value is consumed or remains an ordinary bind.
enum SQLJSONRenderScope {
    static let owners: [SQLJSONOwner] = [.jsonExists, .jsonValue, .jsonQuery]

    static func scope(role: SQLJSONGrammarRole, owner: SQLJSONOwner) -> SQLRenderScope {
        SQLRenderScope(
            namespace: "swifql.sqljson",
            name: roleName(role),
            identityComponents: [
                SQLRenderScope.IdentityComponent(
                    namespace: "swifql.sqljson.owner",
                    name: owner.name
                )
            ]
        )
    }

    /// Resolves the exact grammar role and owner identity from a scope, or nil
    /// when the scope belongs to another semantic layer.
    static func resolve(_ scope: SQLRenderScope?) -> (
        role: SQLJSONGrammarRole,
        owner: SQLJSONOwner
    )? {
        guard let scope else { return nil }
        for role in [SQLJSONGrammarRole.path, .directRuntimeDefaultValue] {
            for owner in owners where scope == self.scope(role: role, owner: owner) {
                return (role, owner)
            }
        }
        return nil
    }

    private static func roleName(_ role: SQLJSONGrammarRole) -> String {
        switch role {
        case .path: "path"
        case .directRuntimeDefaultValue: "directRuntimeDefault"
        }
    }
}

/// Classifies the value operand of a SQL/JSON grammar role and scopes only the
/// exact direct runtime occurrence. Everything else keeps its own structure.
enum SQLJSONContextualValue {
    static func parts(
        for value: SQLable,
        role: SQLJSONGrammarRole,
        owner: SQLJSONOwner
    ) -> [SQLPart] {
        let snapshot = value.parts
        guard snapshot.count == 1, snapshot[0] is SQLPartUnsafeValue else {
            return snapshot
        }
        return [
            SQLScopedPart(
                scope: SQLJSONRenderScope.scope(role: role, owner: owner),
                parts: snapshot
            )
        ]
    }
}
