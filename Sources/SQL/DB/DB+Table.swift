extension DB {
    public struct Table: Equatable, Sendable {
        public let name: String

        public init(_ name: String) {
            self.name = name
        }

        public func column(_ name: String) -> Column {
            Column(table: self, name: name)
        }

        public struct Column: Equatable, Sendable {
            public let table: DB.Table
            public let name: String

            fileprivate init(table: DB.Table, name: String) {
                self.table = table
                self.name = name
            }
        }
    }
}
