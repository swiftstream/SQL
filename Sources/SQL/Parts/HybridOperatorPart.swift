//
//  HybridOperatorPart.swift
//  
//
//  Created by TierraCero on 5/30/23.
//

import Foundation

public struct SQLHybridRepresentationKey: Hashable, Sendable {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) {
        self.namespace = namespace
        self.name = name
    }

    public static let psql = Self(namespace: "swifql", name: "psql")
    public static let postgresql = psql
    public static let mysql = Self(namespace: "swifql", name: "mysql")
    public static let duck = Self(namespace: "swifql", name: "duck")
}

public struct SQLHybridOperator: SQLPart, Equatable {
    public let representations: [SQLHybridRepresentationKey: SQLPartOperator]

    public init(
        representations: [SQLHybridRepresentationKey: SQLPartOperator]
    ) {
        self.representations = representations
    }

    public init(_ psql: SQLPartOperator, _ mysql: SQLPartOperator) {
        self.init(
            representations: [
                .psql: psql,
                .mysql: mysql
            ]
        )
    }

    public init(
        _ psql: SQLPartOperator,
        _ mysql: SQLPartOperator,
        _ duck: SQLPartOperator?
    ) {
        var representations: [SQLHybridRepresentationKey: SQLPartOperator] = [
            .psql: psql,
            .mysql: mysql
        ]
        if let duck {
            representations[.duck] = duck
        }
        self.init(representations: representations)
    }

    public func representation(
        for key: SQLHybridRepresentationKey
    ) -> SQLPartOperator? {
        representations[key]
    }

    public static func == (
        lhs: SQLHybridOperator,
        rhs: SQLHybridOperator
    ) -> Bool {
        guard lhs.representations.count == rhs.representations.count else {
            return false
        }

        return lhs.representations.allSatisfy { key, representation in
            rhs.representations[key] == representation
        }
    }
}

extension SQLHybridOperator: SQLable {
    public var parts: [SQLPart] {
        [self]
    }
}
