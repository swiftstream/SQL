public protocol SQLQuery: SQLable {
    @SQLBuilder var query: SQL { get }
}

public extension SQLQuery {
    var parts: [SQLPart] {
        query.parts
    }
}
