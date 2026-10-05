public protocol SQLQuery: SQLable {
    @SQLBuilder var query: SQLValue { get }
}

public extension SQLQuery {
    var parts: [SQLPart] {
        query.parts
    }
}
