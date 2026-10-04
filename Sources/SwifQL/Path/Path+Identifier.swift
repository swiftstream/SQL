//
//  Path+Identifier.swift
//  SwifQL
//

import Foundation

extension Path {
    /// A value-semantic database-object identifier with optional catalog and
    /// schema qualifiers.
    public struct Identifier {
        public let catalog: String?
        public let schema: String?
        public let name: String

        public init (_ name: String) {
            self.catalog = nil
            self.schema = nil
            self.name = name
        }

        public init (schema: String, name: String) {
            self.catalog = nil
            self.schema = schema
            self.name = name
        }

        public init (catalog: String, schema: String, name: String) {
            self.catalog = catalog
            self.schema = schema
            self.name = name
        }
    }
}

extension Path.Identifier: SQLable {
    public var parts: [SQLPart] {
        var parts: [SQLPart] = []
        if let catalog {
            parts.append(SQLPartCatalog(catalog))
            parts.append(o: .period)
        }
        if let schema {
            parts.append(SQLPartSchema(schema))
            parts.append(o: .period)
        }
        parts.append(SQLPartIdentifier(name))
        return parts
    }
}
