//
//  SQLRenderContext.swift
//  SwifQL
//

import Foundation

public struct SQLRenderScope: Hashable, Sendable {
    public struct IdentityComponent: Hashable, Sendable {
        public let namespace: String
        public let name: String

        public init(namespace: String, name: String) {
            self.namespace = namespace
            self.name = name
        }
    }

    public let namespace: String
    public let name: String
    public let identityComponents: [IdentityComponent]

    public init(namespace: String, name: String) {
        self.init(namespace: namespace, name: name, identityComponents: [])
    }

    public init(
        namespace: String,
        name: String,
        identityComponents: [IdentityComponent]
    ) {
        self.namespace = namespace
        self.name = name
        self.identityComponents = identityComponents
    }
}

extension SQLRenderScope {
    public static let starPattern = SQLRenderScope(
        namespace: "swifql",
        name: "starPattern"
    )
}

public struct SQLRenderContext: Sendable {
    public let scopes: [SQLRenderScope]

    internal init(scopes: [SQLRenderScope] = []) {
        self.scopes = scopes
    }

    public var currentScope: SQLRenderScope? {
        scopes.last
    }

    public func contains(_ scope: SQLRenderScope) -> Bool {
        scopes.contains(scope)
    }

    internal func appending(_ scope: SQLRenderScope) -> Self {
        .init(scopes: scopes + [scope])
    }
}

struct SQLScopedPart: SQLPart {
    let scope: SQLRenderScope
    let parts: [SQLPart]
}
