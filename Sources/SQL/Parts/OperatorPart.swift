//
//  OperatorPart.swift
//  SwifQL
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

public struct SQLSemanticRole: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let starProjection = Self(
        namespace: "swifql",
        name: "starProjection"
    )
}

public protocol SQLSemanticRoleCarryingPart: SQLPart {
    var semanticRole: SQLSemanticRole? { get }
}

public struct SQLPartOperator: SQLPart, Equatable, SQLSemanticRoleCarryingPart {
    var _value: String
    public let semanticRole: SQLSemanticRole?
    
    public init (_ value: String) {
        self._value = value
        self.semanticRole = nil
    }

    public init (_ value: String, semanticRole: SQLSemanticRole) {
        self._value = value
        self.semanticRole = semanticRole
    }

    public static func == (lhs: SQLPartOperator, rhs: SQLPartOperator) -> Bool {
        lhs._value == rhs._value
    }
}

extension SQLPartOperator: SQLable {
    public var parts: [SQLPart] {
        [self]
    }
}
