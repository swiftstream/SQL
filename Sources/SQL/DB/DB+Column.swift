extension DB {
    /// An unqualified SQL column path with its original ordered segments.
    public struct Column: Sendable, KeyPathLastPath {
        public let paths: [String]

        public init(_ paths: String...) {
            self.paths = paths
        }

        public init(_ paths: [String]) {
            self.paths = paths
        }

        public var lastPath: String { paths.last ?? "" }

        public var parts: [SQLPart] {
            [SQLPartKeyPath(paths: paths)]
        }
    }
}

extension DB.Column: SQLable {}
