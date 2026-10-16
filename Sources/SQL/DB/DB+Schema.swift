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

        public func table(_ table: DB.Table) -> Table {
            self.table(table.name)
        }

        public struct Table: Sendable {
            public let schema: DB.Schema
            public let name: String

            fileprivate init(schema: DB.Schema, name: String) {
                self.schema = schema
                self.name = name
            }

            public func column(_ paths: String...) -> Column {
                column(paths)
            }

            public func column(_ paths: [String]) -> Column {
                Column(schema: schema, table: self.name, paths: paths)
            }

            public func column(_ column: DB.Column) -> Column {
                self.column(column.paths)
            }

            public var parts: [SQLPart] {
                [SQLPartTable(schema: schema.name, table: name, catalog: schema.catalog?.name)]
            }

            public struct Column: Sendable, KeyPathLastPath {
                public let schema: DB.Schema
                public let table: String
                public let paths: [String]
                public var name: String { paths.first ?? "" }
                public var lastPath: String { paths.last ?? "" }

                fileprivate init(schema: DB.Schema, table: String, paths: [String]) {
                    self.schema = schema
                    self.table = table
                    self.paths = paths
                }

                public var parts: [SQLPart] {
                    [SQLPartKeyPath(
                        catalog: schema.catalog?.name,
                        schema: schema.name,
                        table: table,
                        paths: paths
                    )]
                }
            }
        }
    }
}

extension DB.Schema: SQLable {
    public var parts: [SQLPart] {
        if let catalog {
            return [SQLPartCatalog(catalog.name), SQLPartOperator.period, SQLPartSchema(name)]
        }
        return [SQLPartSchema(name)]
    }
}

extension DB.Schema.Table: SQLable {}
extension DB.Schema.Table.Column: SQLable {}
