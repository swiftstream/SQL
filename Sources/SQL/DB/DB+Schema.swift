extension DB {
    public struct Schema: ExpressibleByStringLiteral, Equatable, Sendable {
        public let name: String
        public let catalog: DB.Catalog?

        public init(_ name: String) {
            self.name = name
            self.catalog = nil
        }

        public init(catalog: DB.Catalog, name: String) {
            self.name = name
            self.catalog = catalog
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public func inCatalog(_ catalog: DB.Catalog) -> DB.Schema {
            DB.Schema(catalog: catalog, name: name)
        }

        public func table(_ name: String) -> Table {
            Table(schema: self, name: name)
        }

        public struct Table: Equatable, Sendable {
            public let schema: DB.Schema
            public let name: String

            fileprivate init(schema: DB.Schema, name: String) {
                self.schema = schema
                self.name = name
            }

            public func column(_ name: String) -> Column {
                Column(schema: schema, table: self.name, name: name)
            }

            public struct Column: Equatable, Sendable {
                public let schema: DB.Schema
                public let table: String
                public let name: String

                fileprivate init(schema: DB.Schema, table: String, name: String) {
                    self.schema = schema
                    self.table = table
                    self.name = name
                }
            }
        }
    }
}
