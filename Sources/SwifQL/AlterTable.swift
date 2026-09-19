public protocol AlterTableAction: SwifQLable {}

public struct AddColumn: AlterTableAction {
    public let parts: [SwifQLPart]

    public init(
        _ name: String,
        _ type: SwifQL.`Type`
    ) {
        var parts: [SwifQLPart] = []
        parts.append(o: .add)
        parts.append(o: .space)
        parts.append(o: .column)
        parts.append(o: .space)
        parts.append(SwifQLPartColumn(name))
        parts.append(o: .space)
        parts.append(SwifQLPartType(type))
        self.parts = parts
    }
}

public struct AlterTable: SwifQLable {
    public let parts: [SwifQLPart]

    public init(
        _ table: String,
        schema: String? = nil,
        @AlterTableActionBuilder _ actions: () -> [any AlterTableAction]
    ) {
        let actionParts = actions().map(\.parts)
        var parts = SwifQL.alter.table[any: Path.SchemaWithTable(schema: schema, table: table)].parts
        for (index, action) in actionParts.enumerated() {
            if index == 0 {
                parts.append(o: .space)
            } else {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: action)
        }
        self.parts = SwifQLableParts(parts: parts).parts
    }
}
