extension DB {
    public struct Table: Sendable {
        public let name: String

        public init(_ name: String) {
            self.name = name
        }

        public func column(_ paths: String...) -> Column {
            column(paths)
        }

        public func column(_ paths: [String]) -> Column {
            Column(table: self, paths: paths)
        }

        public func column(_ column: DB.Column) -> Column {
            self.column(column.paths)
        }

        public var parts: [SQLPart] {
            [SQLPartTable(name)]
        }

        public struct Column: Sendable, KeyPathLastPath {
            public let table: DB.Table
            public let paths: [String]
            public var name: String { paths.first ?? "" }
            public var lastPath: String { paths.last ?? "" }

            fileprivate init(table: DB.Table, paths: [String]) {
                self.table = table
                self.paths = paths
            }

            public var parts: [SQLPart] {
                [SQLPartKeyPath(table: table.name, paths: paths)]
            }
        }
    }
}

extension DB.Table: SQLable {}
extension DB.Table.Column: SQLable {}
