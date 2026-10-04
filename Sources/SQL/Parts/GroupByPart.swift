/// A readable GROUP BY clause that preserves its selected structural owner.
public struct SQLGroupByPart: SQLPart {
    public let owner: SQLClauseOwner?
    public let fields: [[SQLPart]]

    public init(
        owner: SQLClauseOwner?,
        fields: [[SQLPart]]
    ) {
        self.owner = owner
        self.fields = fields
    }
}
