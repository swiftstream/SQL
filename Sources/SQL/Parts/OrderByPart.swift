/// A readable ORDER BY clause that preserves its selected structural owner.
public struct SQLOrderByPart: SQLPart {
    public let owner: SQLClauseOwner?
    public let items: [[SQLPart]]

    public init(
        owner: SQLClauseOwner?,
        items: [[SQLPart]]
    ) {
        self.owner = owner
        self.items = items
    }
}
