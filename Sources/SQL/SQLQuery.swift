public protocol SQLQuery: SQLable {
    typealias Query = SQLContent

    @SQLBuilder var query: Query { get }
}

public extension SQLQuery {
    var parts: [SQLPart] {
        query.parts
    }
}
