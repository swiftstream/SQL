public protocol AlterTableAction: SQLable {}

public struct AddColumn: AlterTableAction {
    public let parts: [SQLPart]

    public init(
        _ name: String,
        _ type: Type
    ) {
        var parts: [SQLPart] = []
        parts.append(o: .add)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SQLPartColumn(name))
        parts.append(o: .space)
        parts.append(SQLPartType(type))
        self.parts = parts
    }
}

public struct AlterTable: SQLable {
    public let parts: [SQLPart]

    public init(
        _ table: String,
        schema: String? = nil,
        @AlterTableActionBuilder _ actions: () -> [any AlterTableAction]
    ) {
        let actionParts = actions().map(\.parts)
        var parts = SQL.root.alter.table[any: Path.SchemaWithTable(schema: schema, table: table)].parts
        for (index, action) in actionParts.enumerated() {
            if index == 0 {
                parts.append(o: .space)
            } else {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: action)
        }
        self.parts = SQLableParts(parts: parts).parts
    }
}
