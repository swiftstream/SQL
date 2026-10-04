//
//  IdentifierPart.swift
//  SwifQL
//

import Foundation

/// A terminal structural identifier for database objects that are not tables,
/// columns, aliases, or key paths.
public struct SQLPartIdentifier: SQLPart {
    public let name: String

    public init (_ name: String) {
        self.name = name
    }
}
