extension DB {
    public struct Catalog: ExpressibleByStringLiteral, Equatable, Sendable {
        public let name: String

        public init(_ name: String) {
            self.name = name
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        @_disfavoredOverload
        public func schema(_ schema: DB.Schema) -> Schema {
            Schema(catalog: self, schema: schema.inCatalog(self))
        }

        public func schema(_ name: String) -> Schema {
            schema(DB.Schema(name))
        }

        public struct Schema: Equatable, Sendable {
            public let catalog: DB.Catalog
            public let schema: DB.Schema

            fileprivate init(catalog: DB.Catalog, schema: DB.Schema) {
                self.catalog = catalog
                self.schema = schema
            }

            public func table(_ name: String) -> DB.Schema.Table {
                schema.table(name)
            }
        }
    }
}
