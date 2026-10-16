extension DB {
    /// A database object identifier with optional catalog and schema scope.
    public struct Object: Sendable {
        public let catalog: DB.Catalog?
        public let schema: DB.Schema?
        public let name: String

        public init(_ name: String) {
            self.init(catalog: nil, schema: nil, name: name)
        }

        public init(schema: DB.Schema, name: String) {
            self.init(catalog: nil, schema: schema, name: name)
        }

        public init(catalog: DB.Catalog, schema: DB.Schema, name: String) {
            self.catalog = catalog
            self.schema = schema
            self.name = name
        }

        public init(catalog: DB.Catalog? = nil, schema: DB.Schema? = nil, name: String) {
            self.catalog = catalog
            self.schema = schema
            self.name = name
        }

        public var parts: [SQLPart] {
            var parts: [SQLPart] = []
            if let catalog = catalog ?? schema?.catalog {
                parts.append(SQLPartCatalog(catalog.name))
                parts.append(o: .period)
            }
            if let schema {
                parts.append(SQLPartSchema(schema.name))
                parts.append(o: .period)
            }
            parts.append(SQLPartIdentifier(name))
            return parts
        }
    }
}

extension DB.Object: SQLable {}
