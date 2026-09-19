import Foundation

public protocol TableDefinition: SwifQLable {}

extension NewColumn: TableDefinition {}
extension GeneratedColumn: TableDefinition {}

public struct CreateTable: SwifQLable {
    public let parts: [SwifQLPart]

    public init(
        _ table: String,
        schema: String? = nil,
        @TableDefinitionBuilder _ definitions: () -> [any TableDefinition]
    ) {
        let snapshots: [SwifQLable] = definitions().map {
            SwifQLableParts(parts: $0.parts)
        }
        self.parts = SwifQL.create.table[any: Path.SchemaWithTable(schema: schema, table: table)]
            .tableDefinitions(snapshots)
            .parts
    }
}

extension SwifQLable {
    /// Appends a parenthesized, comma-separated table-definition list.
    public func tableDefinitions(_ definitions: SwifQLable...) -> SwifQLable {
        tableDefinitions(definitions)
    }

    /// Appends a parenthesized, comma-separated table-definition list.
    public func tableDefinitions(_ definitions: [SwifQLable]) -> SwifQLable {
        var parts = self.parts
        parts.appendSpaceIfNeeded()
        parts.append(o: .openBracket)
        for (index, definition) in definitions.enumerated() {
            if index > 0 {
                parts.append(o: .comma, .space)
            }
            parts.append(contentsOf: definition.parts)
        }
        parts.append(o: .closeBracket)
        return SwifQLableParts(parts: parts)
    }
}
